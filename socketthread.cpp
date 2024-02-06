#include "socketthread.h"

SocketThread::SocketThread(DeviceService &deviceService, qintptr socketDescription, QObject *parent)
    : QObject(parent), m_deviceService(deviceService),
      m_socketDescription(socketDescription)
{
qDebug(logSocketThread()) << "Initializated";
}

SocketThread::~SocketThread() {
qDebug(logSocketThread()) << "Destroyed";
    delete m_socket;
}

void SocketThread::startSocketThread() {
qDebug(logSocketThread()) << "Started";
    m_socket = new QTcpSocket();
    m_socket->setSocketDescriptor(m_socketDescription);
    QObject::connect(m_socket, &QTcpSocket::disconnected, this, &SocketThread::slotDisconnected);

    hostIp = QHostAddress(m_socket->peerAddress().toIPv4Address()).toString();

qDebug(logSocketThread()) << "Ip --" << QHostAddress(m_socket->peerAddress().toIPv4Address()).toString();

    if(m_deviceService.checkIp(hostIp)) { //проверяем ip в database и получаем name и passphrase (m_deviceService)
qDebug(logSocketThread()) << "Known member";
        passphraseAlian = m_deviceService.getValue(hostIp, HashType::TYPE_ALIAN_PASS).toLatin1();
        permissionMode = m_deviceService.getValue(hostIp, HashType::TYPE_MODE).toInt();
        QObject::connect(m_socket, &QTcpSocket::readyRead, this, &SocketThread::slotReadyRead);
    }
    else {
qDebug(logSocketThread()) << "Unknown member";
        privatekey = cWrapper.getPrivateKey("private.pem");
        QObject::connect(m_socket, &QTcpSocket::readyRead, this, &SocketThread::slotUnknownDevice);
    }

}

void SocketThread::slotUnknownDevice() {
qDebug(logSocketThread()) << Q_FUNC_INFO;

    QByteArray encryptedKey;

    QDataStream in(m_socket);
    in.setVersion(QDataStream::Qt_DefaultCompiledVersion);
    in.startTransaction();
    in >> packetType;

    if(packetType == PacketType::TYPE_KEYADD) {
qDebug(logSocketThread()) << "Adding new device";
        QByteArray encryptedNameAlian;

        in >> encryptedKey >> encryptedNameAlian;
        if(!in.commitTransaction()) {
            qCritical(logSocketThread()) << "Could not add new device";
            sendResponse(Status::ERROR_SIZE_KEY);
            return;
        }
        QByteArray currentCode = m_deviceService.getCurrentCode();
        QByteArray decryptedNameAlian = cWrapper.decryptAES(currentCode, encryptedNameAlian);
        QByteArray decryptedPubKey = cWrapper.decryptAES(currentCode, encryptedKey);
        infoClient.append(hostIp);
        infoClient.append(decryptedNameAlian); //ip, alianName, alianPubKey, alianId, localPass, alianPass
        infoClient.append(decryptedPubKey);

        emit changeCode();

        if(decryptedPubKey.size() == Config::sizePublicKey &&  !decryptedNameAlian.isEmpty()) {
qDebug(logSocketThread()) << "Size public key: correct --- name:" << "decryptedNameAlian";
            QByteArray id = Registry::getDeviceId();
            QByteArray passphrase = m_deviceService.getPassphrase();
            infoClient.append(passphrase);

            RSA* publicAlian = cWrapper.getPublicKey(decryptedPubKey);
            QByteArray pubKey = cWrapper.readFile("public.pem");

            QByteArray name = m_deviceService.getName();
            QByteArray encryptedName = cWrapper.encryptAES(passphrase, name);
            QByteArray encryptedId = cWrapper.encryptAES(passphrase, id);
            encryptedPassphrase = cWrapper.encryptRSA(publicAlian, passphrase);
            QByteArray encryptedPublicKey = cWrapper.encryptAES(currentCode, pubKey);

            QDataStream out(m_socket);
            out.setVersion(QDataStream::Qt_DefaultCompiledVersion);
            out << Status::ACCEPT_KEY << encryptedName << encryptedId << encryptedPassphrase << encryptedPublicKey;

            cWrapper.freeRSAKey(publicAlian);
        }
        else {
qCritical(logSocketThread()) << "Size public key: wrong";
            sendResponse(Status::ERROR_SIZE_KEY);
        }
        return;
    }
    if(packetType == PacketType::TYPE_OLDFRIEND) {
        QByteArray encryptedId;
qDebug(logSocketThread()) << "Connecting old device";
        in >> encryptedId >> encryptedKey;
        if(!in.commitTransaction()) {
qCritical(logSocketThread()) << "Could not connect old device";
            sendResponse(Status::ERROR_SIZE_KEY);
            return;
        }

        QByteArray decryptedAlianPassphrase = cWrapper.decryptRSA(privatekey, encryptedKey);
        QByteArray decryptedId = cWrapper.decryptAES(decryptedAlianPassphrase, encryptedId);
        QByteArray passphrase = encryptedPassphrase.isEmpty() ? m_deviceService.getPassphrase() : infoClient.takeLast().toUtf8();

        infoClient.append(decryptedId); //ip, alianName, alianPubKey, alianId, localPass, alianPass
        infoClient.append(passphrase);
        infoClient.append(decryptedAlianPassphrase);
//qDebug(logSocketThread()) << "Alian information:" << decryptedId << decryptedId.size() << " - " <<  decryptedAlianPassphrase << decryptedAlianPassphrase.size();

        if(encryptedPassphrase.isEmpty()) {
qDebug(logSocketThread()) << "Request information about me";
            QList<QString> infoOldClient = m_deviceService.getInfoOldClient(decryptedId);
            if(!infoOldClient.isEmpty()) {
                QByteArray pubAlian = infoOldClient.at(0).toLatin1(); //get from SQLite
                RSA* publicAlian = cWrapper.getPublicKey(pubAlian);
                encryptedPassphrase = cWrapper.encryptRSA(publicAlian, passphrase);

                QDataStream out(m_socket);
                out.setVersion(QDataStream::Qt_DefaultCompiledVersion);
                out << encryptedPassphrase;

                infoClient.prepend(infoOldClient.at(1));
                infoClient.prepend(infoOldClient.at(2));
qDebug(logSocketThread()) << "infoClient";
                m_deviceService.setValue(hostIp, infoClient);
            }
            else {
qDebug(logSocketThread()) << "infoOldClient is empty";
                QDataStream out(m_socket);
                out.setVersion(QDataStream::Qt_DefaultCompiledVersion);
                out << QByteArray(NULL);
            }
        }
        else {
qDebug(logSocketThread()) << "Registration from server" << "infoClient";
            m_deviceService.registryFromServer(infoClient);

            QString id = infoClient.at(3);
            QString ip = infoClient.at(0);
            QString name = infoClient.at(1);
            QString mode = name.right(1);
            name.chop(1);

            QString localPassphrase = infoClient.at(4);
            QString alianPassphrase = infoClient.at(5);
            QList<QString> values;
            values << name << mode << id << localPassphrase << alianPassphrase;
            m_deviceService.setValue(ip, values);
        }
        return;
    }
    m_socket->close();
qCritical(logSocketThread()) << "Error closing host";
}

void SocketThread::slotReadyRead() {
qDebug(logSocketThread()) << Q_FUNC_INFO;

    QDataStream in(m_socket);
    in.setVersion(QDataStream::Qt_DefaultCompiledVersion);
    in.startTransaction();
    in >> packetType;

    if(packetType == PacketType::TYPE_DELETE) {
qDebug(logSocketThread()) << "Removing old device" << hostIp;
        m_deviceService.deleteDevice(hostIp);
        return;
    }

    if(packetType == PacketType::TYPE_REQUEST_FILE) {
qDebug(logSocketThread()) << "Getting information of files from" << hostIp;
        QList<QVector<QString>> askingData;
        qint64 size = 0;
        while(m_socket->bytesAvailable()) {
            QByteArray encryptedFileInfo;
            in >> encryptedFileInfo;
            if(encryptedFileInfo.isEmpty()) {
qDebug(logSocketThread()) << "wait...";
                in.rollbackTransaction();
                return;
            }
            decryptedPlain = cWrapper.decryptAES(passphraseAlian, encryptedFileInfo);
            if(!decryptedPlain.isEmpty()) {
                if(decryptedPlain.contains('|')) {
                    QStringList files = QString(decryptedPlain).split('|');
                    size += files.last().toULongLong();
                    files.append(GuiService::convertSize(files.last().toULongLong()));
                    askingData.append(files);
                }
                else askingData.append({ decryptedPlain });
            }
            else {
qDebug(logSocketThread()) << "FAIL decrypt";
                in.abortTransaction();
                sendResponse(Status::ERROR_SIZE_PLAIN);
                return;
            }
        }
        if(!in.commitTransaction()) {
            qCritical(logSocketThread()) << "Error sizeFile or sizePlain or encryptedPlain - FAIL commitTransaction";
            sendResponse(Status::ERROR_COOKIES);
            return;
        }
qDebug(logSocketThread()) << "END informations of files:\n"; //<< askingData;

        if(permissionMode == 1) {
            QString token = askingData.takeFirst().at(0);
            for(QVector<QString> fileInfo : askingData) {
                m_deviceService.acceptFile(hostIp, token, fileInfo.at(0), fileInfo.at(2) + "." + fileInfo.at(1), fileInfo.at(3));
            }
        }
        else if(permissionMode == 0) {
            QString type = askingData.size() == 2 ? "file" : "files";
            m_deviceService.askData(true, type, hostIp, GuiService::convertSize(size), askingData);
        }
        sendResponse(Status::ACCEPT_COOKIES);
        return;
    }

    if(packetType == PacketType::TYPE_STOP_FILE) {
        QObject::disconnect(m_socket, &QTcpSocket::bytesWritten, this, &SocketThread::sendPartOfFile);
        qDebug(logSocketThread()) << "TYPE_STOP_FILE: before --" << m_deviceService.cookies;
        QString ipToken = hostIp+p_fileToken;
        QHash<QString, QString> files;
        if(m_deviceService.cookies.contains(ipToken)) {
            files = m_deviceService.cookies.value(ipToken);
        }
        files.insert(p_fileId, file->fileName());
        m_deviceService.cookies.insert(ipToken, files);

        qDebug(logSocketThread()) << "TYPE_STOP_FILE: after --" << m_deviceService.cookies;

        file->close();
        emit m_deviceService.changedProgress(false, hostIp, p_fileId, -1);
        delete file;
        return;
    }

    QByteArray encryptedPlain;
    in >> encryptedPlain;

    if(packetType == PacketType::TYPE_CANCEL_REQUEST) {
        if(!in.commitTransaction()) {
            qCritical(logSocketThread()) << "Error cancel request";
            return;
        }
        decryptedPlain = cWrapper.decryptAES(passphraseAlian, encryptedPlain);
        QStringList cancelingRequest = QString(decryptedPlain).split('|');
        m_deviceService.deleteCookie(hostIp+cancelingRequest.first(), cancelingRequest.last());
        emit m_deviceService.deleteIrrelevantFile(true, hostIp, cancelingRequest.first(), cancelingRequest.last());
        return;
    }

    if(packetType == PacketType::TYPE_MSG) {
qDebug(logSocketThread()) << "Getting text from" << hostIp;
        if(!in.commitTransaction()) {
            qCritical(logSocketThread()) << "Error sizePlain or encryptedPlain - FAIL commitTransaction";
            sendResponse(Status::ERROR_PLAIN);
            return;
        }
        decryptedPlain = cWrapper.decryptAES(passphraseAlian, encryptedPlain);
        if(!decryptedPlain.isEmpty()) {
            if(permissionMode == 1) {
                emit acceptMessage(decryptedPlain);
            }
            else if(permissionMode == 0) {
                QList<QVector<QString>> askingData;
                QVector<QString> data = {decryptedPlain};
                askingData.append(data);
                m_deviceService.askData(true, "text", hostIp, QString::number(decryptedPlain.size()), askingData);
            }
            sendResponse(Status::ACCEPT_PLAIN);
        }
        else {
qDebug(logSocketThread()) << "ERROR_SIZE_PLAIN";
           sendResponse(Status::ERROR_SIZE_PLAIN);
        }
        return;
    }

    if(packetType == PacketType::TYPE_ACCEPT_FILE) {  
        if(!in.commitTransaction()) {
            qCritical(logSocketThread()) << "Error fileName - FAIL commitTransaction";
            sendResponse(Status::ERROR_PLAIN);
            return;
        }
        decryptedPlain = cWrapper.decryptAES(passphraseAlian, encryptedPlain);
        if(!decryptedPlain.isEmpty() && decryptedPlain.contains('|')) {
            QStringList cookieInfo = QString(decryptedPlain).split('|');
            p_fileToken = cookieInfo.first();
            p_fileId = cookieInfo.last();
            QString filePath = m_deviceService.getFilePath(hostIp+p_fileToken, p_fileId);
//m_deviceService.deleteIrrelevantFile(hostIp, cookieInfo.first(), p_fileId);
            qDebug(logSocketThread()) << filePath;

            if(QFileInfo::exists(filePath)) {
                sendResponse(Status::FILE_READY);
                file = new QFile(filePath);
                localPassphrase = m_deviceService.getValue(hostIp, HashType::TYPE_LOCAL_PASS).toLatin1();
                if(file->open(QIODevice::ReadOnly)) {
                    timeStart = QTime::currentTime();
                    emit m_deviceService.startOperationFile(false, hostIp, p_fileId);
                    QObject::connect(m_socket, &QTcpSocket::bytesWritten, this, &SocketThread::sendPartOfFile);
                    qDebug(logSocketThread()) << "START SENDING FILE";
                    sendPartOfFile();
                }
                else {
                    qCritical(logSocketThread()) << "Can't open file!";
                    sendResponse(Status::ERROR_FILE);
                }
            }
            else sendResponse(Status::ERROR_EXISTS_FILE);
        }
        else {
           sendResponse(Status::ERROR_SIZE_PLAIN);
        }
        return;
    }

    if(packetType == PacketType::TYPE_REJECT_FILE) {
        if(!in.commitTransaction()) {
            qCritical(logSocketThread()) << "Error reject data";
            return;
        }
        decryptedPlain = cWrapper.decryptAES(passphraseAlian, encryptedPlain);
        QStringList rejectingData = QString(decryptedPlain).split('|');
        m_deviceService.deleteCookie(hostIp+rejectingData.first(), rejectingData.last());
        m_deviceService.deleteIrrelevantFile(false, hostIp, rejectingData.first(), rejectingData.last());
        return;
    } 
}

void SocketThread::stopUploadFile(QString ip, QString token, QString id) {
    if(hostIp == ip && token == p_fileToken && id == p_fileId) {
        QObject::disconnect(m_socket, &QTcpSocket::bytesWritten, this, &SocketThread::sendPartOfFile);
        qDebug(logSocketThread()) << "stopUploadFile: before --" << m_deviceService.cookies;
        QString ipToken = hostIp+p_fileToken;
        QHash<QString, QString> files;
        if(m_deviceService.cookies.contains(ipToken)) {
            files = m_deviceService.cookies.value(ipToken);
        }
        files.insert(p_fileId, file->fileName());
        m_deviceService.cookies.insert(ipToken, files);

        qDebug(logSocketThread()) << "stopUploadFile: after --" << m_deviceService.cookies;

        file->close();
        emit m_deviceService.changedProgress(false, hostIp, p_fileId, -1);
        delete file;

        sendResponse(Status::FILE_STOP);
    }
}

void SocketThread::sendPartOfFile() {
    if(!file->atEnd()) {
        countSendFile++;
        QByteArray tmpBlock = file->read(Config::fileSegmentSize - 32);
        QByteArray encryptedBlock = cWrapper.encryptAES(localPassphrase, tmpBlock);
        m_socket->write(encryptedBlock);
//qDebug() << tmpBlock.size() << encryptedBlock.size();
        sizeSentData += encryptedBlock.size();
        emit m_deviceService.changedProgress(false, hostIp, p_fileId, double(sizeSentData) / double(file->size()) * 100);
    }
    else {
        QTime time(0, 0, 0, 0);
        QTime timeEnd = time.addMSecs(timeStart.msecsTo(QTime::currentTime()));
        QString timeString = timeEnd.toString("mm:ss.zzz");
        emit m_deviceService.endDownloadFile(hostIp, p_fileId, timeString, "");
        QObject::disconnect(m_socket, &QTcpSocket::bytesWritten, this, &SocketThread::sendPartOfFile);
qDebug(logClient()) << "END SENDING FILE -- countSendFile:" << countSendFile;
        file->close();
        delete file;
    }
}

void SocketThread::slotDisconnected() {
qDebug(logSocketThread()) << "Client disconnected";
    cWrapper.freeRSAKey(privatekey);
    emit finished();
}

bool SocketThread::sendResponse(QByteArray status) {
    QDataStream out(m_socket);
    out.setVersion(QDataStream::Qt_DefaultCompiledVersion);
    out << status;
    if(!m_socket->waitForBytesWritten(5000)) {
        qCritical(logSocketThread()) << "Could not write response to client";
        m_socket->disconnectFromHost();
        return false;
    }
    return true;
}





















