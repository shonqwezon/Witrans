#include "client.h"

Client::Client(int typeData, QString data, QByteArray passphrase, QHostAddress host, quint16 port, QObject *parent)
    : QObject(parent),
      m_typeData(typeData),
      m_data(data),
      m_passphrase(passphrase),
      m_host(host),
      m_port(port)
{
qDebug(logClient()) << "Initialization string";
    m_socket = new QTcpSocket(this);
}

Client::Client(int typeData, QList<QByteArray> list, QByteArray passphrase, QHostAddress host, quint16 port, QObject *parent)
    : QObject(parent),
      m_typeData(typeData),
      m_list(list),
      m_passphrase(passphrase),
      m_host(host),
      m_port(port)
{
qDebug(logClient()) << "Initialization list";
    m_socket = new QTcpSocket(this);
}

void Client::startClient() {
qDebug(logClient()) << "Started";
    QObject::connect(m_socket, &QTcpSocket::disconnected, this, &Client::slotDisconnected);
//    QObject::connect(m_socket, &QAbstractSocket::errorOccurred, this, &Client::slotError);

    m_socket->connectToHost(m_host, m_port);
    if(m_socket->waitForConnected()) {
        m_socket->setSocketOption(QAbstractSocket::LowDelayOption, 0);
        slotConnected();
    }
    else {
        qCritical(logClient()) << "Wrong ip";
        closeHost(RequestType::TYPE_WRONGIP);
    }
}

void Client::slotConnected() {
qDebug(logClient()) << "Connected";
    hostIp = QHostAddress(m_socket->peerAddress().toIPv4Address()).toString();
    QByteArray encryptedPlain;

    QDataStream out(m_socket);
    out.setVersion(QDataStream::Qt_DefaultCompiledVersion);

    switch(m_typeData) {
        case PacketType::TYPE_KEYADD: {
qDebug(logClient()) << "TYPE: TYPE_KEYADD";

            QObject::connect(m_socket, &QTcpSocket::readyRead, this, &Client::slotReadKey);

            QByteArray pubKey = cWrapper.readFile("public.pem");

            QByteArray encryptedLocalPubKey = cWrapper.encryptAES(m_list.first(), pubKey); //публичный ключ в временном ключе
            QByteArray encryptedName = cWrapper.encryptAES(m_list.first(), m_list.last()); //name в временном ключе

            out << m_typeData << encryptedLocalPubKey << encryptedName;
            if(!m_socket->waitForBytesWritten()) {
                qCritical(logClient()) << "Could not send info data";
                closeHost(RequestType::TYPE_SOMEERROR);
                return;
            }
            return;
        }
        case PacketType::TYPE_OLDFRIEND: {
qDebug(logClient()) << "TYPE: TYPE_OLDFRIEND";
            QByteArray publicData = m_data.toUtf8();
            publickey = cWrapper.getPublicKey(publicData);
            sendPersonalInfo(true);
            return;
        }
        case PacketType::TYPE_DELETE: {
qDebug(logClient()) << "TYPE: TYPE_DELETE";
            out << m_typeData;
            if(!m_socket->waitForBytesWritten()) {
                qCritical(logClient()) << "Could not send delete data";
                closeHost(RequestType::TYPE_SOMEERROR);
                return;
            }
            closeHost(RequestType::TYPE_NOERROR);
            return;
        }
        case PacketType::TYPE_CANCEL_REQUEST: {
qDebug(logClient()) << "TYPE: TYPE_CANCEL_REQUEST";
            QByteArray plain = m_data.toUtf8();
            encryptedPlain = cWrapper.encryptAES(m_passphrase, plain);
            out << m_typeData << encryptedPlain;
            if(!m_socket->waitForBytesWritten()) {
                qCritical(logClient()) << "Could not send delete data";
                closeHost(RequestType::TYPE_SOMEERROR);
                return;
            }
            closeHost(RequestType::TYPE_NOERROR);
            return;
        }
        case PacketType::TYPE_MSG: {
qDebug(logClient()) << "TYPE: TYPE_MSG";
            QObject::connect(m_socket,  &QTcpSocket::readyRead, this, &Client::slotReadResponse);

            QByteArray plain = m_data.toUtf8();
            encryptedPlain = cWrapper.encryptAES(m_passphrase, plain);

            out << m_typeData << encryptedPlain;
            if(!m_socket->waitForBytesWritten()) {
                qCritical(logClient()) << "Could not send info data";
                closeHost(RequestType::TYPE_SOMEERROR);
                return;
            }
            return;
        }
        case PacketType::TYPE_REQUEST_FILE: {
qDebug(logClient()) << " TYPE: TYPE_REQUEST_FILE";
            QObject::connect(m_socket,  &QTcpSocket::readyRead, this, &Client::slotReadResponse);
qDebug(logClient()) << "Information of files:" << m_list.size() - 1 << "-- and token";
            out << m_typeData;
            for(QByteArray plain : m_list) {
                encryptedPlain = cWrapper.encryptAES(m_passphrase, plain);
                out << encryptedPlain;
            }
            return;
        }
        case PacketType::TYPE_ACCEPT_FILE: {
qDebug(logClient()) << "TYPE: TYPE_FILE";
            QObject::connect(m_socket,  &QTcpSocket::readyRead, this, &Client::slotReadResponse);
            QByteArray plain = m_list.first();
            encryptedPlain = cWrapper.encryptAES(m_passphrase, plain);
            out << m_typeData << encryptedPlain;
            return;
        }
        case PacketType::TYPE_REJECT_FILE: {
            QByteArray plain = m_data.toLatin1();
            encryptedPlain = cWrapper.encryptAES(m_passphrase, plain);
            out << m_typeData << encryptedPlain;
            if(!m_socket->waitForBytesWritten()) {
                qCritical(logClient()) << "Could not reject data";
                closeHost(RequestType::TYPE_SOMEERROR);
                return;
            }
            closeHost(RequestType::TYPE_NOERROR);
            return;
        }
    }
}

void Client::slotReadKey() {
    QByteArray request;

    QDataStream in(m_socket);
    in.setVersion(QDataStream::Qt_DefaultCompiledVersion);
    in.startTransaction();
    in >> request;

//qDebug(logClient()) << "Started slotReadKey" << request;

    if(request == Status::ACCEPT_KEY) { //используется при добавлении нового пользователя
qDebug(logClient()) << "Accepted key";
        RSA* privateKey = cWrapper.getPrivateKey("private.pem");

        QByteArray encryptedName;
        QByteArray encryptedId;
        QByteArray encryptedPassphrase;
        QByteArray encryptedPublicKey;

        in >> encryptedName >> encryptedId >> encryptedPassphrase >> encryptedPublicKey;

        if(!in.commitTransaction()) {
            qCritical(logClient()) << "Error got alian public key + id + passphrse + name";
            closeHost(RequestType::TYPE_SOMEERROR);
            return;
        }

        QByteArray decryptedPublicKey = cWrapper.decryptAES(m_list.first(), encryptedPublicKey); //decrypt чужой публичный ключ временным ключом
        QByteArray decryptedPassphraseAlian = cWrapper.decryptRSA(privateKey, encryptedPassphrase);
        QByteArray decryptedId = cWrapper.decryptAES(decryptedPassphraseAlian, encryptedId);
        QByteArray decryptedName = cWrapper.decryptAES(decryptedPassphraseAlian, encryptedName);

        publickey = cWrapper.getPublicKey(decryptedPublicKey);
        infoClient.append(hostIp); //ip, alianName, alianPubKey, alianId, localPass, alianPass
        infoClient.append(decryptedName + m_list.last().right(1));
        infoClient.append(decryptedPublicKey);
        infoClient.append(decryptedId);
        infoClient.append(m_passphrase);
        infoClient.append(decryptedPassphraseAlian);
qDebug(logClient()) << "Alian data: ..."; //<< decryptedName << decryptedName.size() << " - " << decryptedId << decryptedId.size() << " - " <<  decryptedPassphraseAlian << decryptedPassphraseAlian.size() << " - " << decryptedPublicKey.size();

        cWrapper.freeRSAKey(privateKey);
        sendPersonalInfo(false);
        return;
    }
    if(request == Status::ERROR_SIZE_KEY) {
        qCritical(logClient()) << "Error size key";
        closeHost(RequestType::TYPE_WRONGKEY);
        return;
    }
}

void Client::sendPersonalInfo(bool mode) {
qDebug(logClient()) << Q_FUNC_INFO << mode;
    QDataStream out(m_socket);
    out.setVersion(QDataStream::Qt_DefaultCompiledVersion);
    QByteArray id = Registry::getDeviceId();

    QByteArray encryptedId = cWrapper.encryptAES(m_passphrase, id);
    QByteArray encryptedPassphrase = cWrapper.encryptRSA(publickey, m_passphrase);

    out << PacketType::TYPE_OLDFRIEND << encryptedId << encryptedPassphrase;
    if(!m_socket->waitForBytesWritten(5000)) {
        qCritical(logClient()) << "Could not send personal info";
        closeHost(RequestType::TYPE_SOMEERROR);
        return;
    }

    if(mode) {
qDebug(logClient()) << "Getting alian encryptedPassphras";
        if(!m_socket->waitForReadyRead()) {
            qCritical(logClient()) << "Could not get alian encryptedPassphrase";
            closeHost(RequestType::TYPE_SOMEERROR);
            return;
        }
        RSA* privateKey = cWrapper.getPrivateKey("private.pem");
        QByteArray encryptedPassphrase;

        QDataStream in(m_socket);
        in.setVersion(QDataStream::Qt_DefaultCompiledVersion);
        in.startTransaction();
        in >> encryptedPassphrase;
        if(!in.commitTransaction()) {
            qCritical(logClient()) << "Could not got alian encryptedPassphrase";
            closeHost(RequestType::TYPE_SOMEERROR);
            return;
        }
        if(encryptedPassphrase.isEmpty()) {
           qCritical(logClient()) << "Alian encryptedPassphrase is NULL";
           closeHost(RequestType::TYPE_SOMEERROR);
           return;
        }
        QByteArray decryptedPassphrase = cWrapper.decryptRSA(privateKey, encryptedPassphrase); //записать в hash рядом с ip и id
        cWrapper.freeRSAKey(privateKey);

qDebug(logClient()) << "Completed connecting to device" << "decryptedPassphrase";
        infoClient.append(hostIp);
        infoClient.append(m_passphrase);                             //local
        infoClient.append(decryptedPassphrase);                      //alian
        emit saveToHash(infoClient);
    }
    else {
qDebug(logClient()) << "Completed binding!";
        emit saveToBase(infoClient);
    }
    closeHost(RequestType::TYPE_NOERROR);
}

void Client::getPartOfFile() {
//qDebug(logClient()) << countGetFile << fail << sizeReceivedData << fileSize << m_socket->bytesAvailable() << tempBytes.size();
    tempBytes += m_socket->readAll();
    if(tempBytes.last(Status::FILE_STOP.size()) == Status::FILE_STOP) {
        QStringList entryInfo = QString(m_list.first()).split('|');
        QObject::disconnect(m_socket,  &QTcpSocket::readyRead, this, &Client::getPartOfFile);
        file->close();
        emit changedProgress(true, entryInfo.first(), entryInfo.last(), -1);
        delete file;
        closeHost(RequestType::TYPE_NOERROR);
        return;
    }
    if(tempBytes.size() >= Config::fileSegmentSize || tempBytes.size() > (fileSize - sizeReceivedData)) {
        countGetFile++;
        QByteArray tmpBlock = tempBytes.first(Config::fileSegmentSize);
        tempBytes.remove(0, tmpBlock.size());
//qDebug() << tmpBlock.size();
        QByteArray decryptedBlock = cWrapper.decryptAES(passphraseAlian, tmpBlock);
        QStringList entryInfo = QString(m_list.first()).split('|');
        if(!decryptedBlock.isEmpty()) {
            qint64 blockSize = file->write(decryptedBlock);
            sizeReceivedData += blockSize;
            emit changedProgress(true, entryInfo.first(), entryInfo.last(), double(sizeReceivedData) / double(fileSize) * 100);
        }
        else {
            qDebug(logSocketThread()) << "FAIL decrypt blockFile";
            closeHost(RequestType::TYPE_ERROR_DECRYPT_FILE);
            return;
        }
        if(sizeReceivedData == fileSize) {
            QObject::disconnect(m_socket,  &QTcpSocket::readyRead, this, &Client::getPartOfFile);
            file->close();
            QTime time(0, 0, 0, 0);
            QTime timeEnd = time.addMSecs(timeStart.msecsTo(QTime::currentTime()));
            QString timeString = timeEnd.toString("mm:ss.zzz");

            emit endDownloadFile(entryInfo.first(), entryInfo.last(), timeString, file->fileName());
            qDebug(logClient()) << "\n"
                                << "File path:" << file->fileName() << "\n"
                                << "CountSend FINAL:" << countGetFile << "\n"
                                << "Fail:" << fail << "\n"
                                << "SizeReceivedData END:" << sizeReceivedData << "\n"
                                << "Time final:" << timeString << "\n"
                                << "Time period:" << timeStart.toString("mm:ss.zzz") << " --- " << QTime::currentTime().toString("mm:ss.zzz");
            delete file;
            closeHost(RequestType::TYPE_NOERROR);
        }
    }
}

void Client::stopDownloadFile(QString ip, QString token, QString id) {
    QStringList entryInfo = QString(m_list.first()).split('|');
    if(m_host.toString() == ip && token == entryInfo.first() && id == entryInfo.last()) {
        QObject::disconnect(m_socket,  &QTcpSocket::readyRead, this, &Client::getPartOfFile);
        file->close();
        emit changedProgress(true, entryInfo.first(), entryInfo.last(), -1);
        delete file;

        QDataStream out(m_socket);
        out.setVersion(QDataStream::Qt_DefaultCompiledVersion);
        out << PacketType::TYPE_STOP_FILE;
        if(!m_socket->waitForBytesWritten()) {
            qCritical(logClient()) << "Could not stopped file";
            closeHost(RequestType::TYPE_ERROR_STOP_FILE);
            return;
        }

        closeHost(RequestType::TYPE_NOERROR);
        qDebug(logClient()) << "stopDownloadFile:" << ip << token << id;
    }
}

void Client::slotReadResponse() {
    QByteArray request;
    QDataStream in(m_socket);
    in.setVersion(QDataStream::Qt_DefaultCompiledVersion);
    in.startTransaction();
    in >> request;
    if(!in.commitTransaction()) {
        qCritical(logClient()) << "Error get request from server";
        closeHost(RequestType::TYPE_SOMEERROR);
        return;
    }
qDebug(logClient()) << "Response from server --" << "request";

    if(request == Status::ACCEPT_PLAIN) {
        qCritical(logClient()) << "Accept plain";
        closeHost(RequestType::TYPE_NOERROR);
        return;
    }
    if(request == Status::ERROR_PLAIN) {
        qCritical(logClient()) << "Error plain";
        closeHost(RequestType::TYPE_SOMEERROR);
        return;
    }
    if(request == Status::ERROR_SIZE_PLAIN) {
        qCritical(logClient()) << "Error size of plain";
        closeHost(RequestType::TYPE_SOMEERROR);
        return;
    }

    if(request == Status::ACCEPT_COOKIES) {
        qCritical(logClient()) << "Cookies accept";
        closeHost(RequestType::TYPE_ACCEPT_COOKIES);
        return;
    }
    if(request == Status::ERROR_COOKIES) {
        qCritical(logClient()) << "Cookies ERROR";
        closeHost(RequestType::TYPE_ERROR_COOKIES);
        return;
    }

    if(request == Status::FILE_READY) {
        qDebug(logClient()) << "START GETTING FILE";
        QObject::disconnect(m_socket,  &QTcpSocket::readyRead, this, &Client::slotReadResponse);
        QObject::connect(m_socket,  &QTcpSocket::readyRead, this, &Client::getPartOfFile);
        timeStart = QTime::currentTime();
        QString fileName = m_list.at(1);
        QString filePath = Registry::getDownloadPath() + fileName;
        if(!QDir(Registry::getDownloadPath()).exists()) {
            qDebug(logClient()) << "Created general directory";
            QDir().mkpath(Registry::getDownloadPath());
        }
        fileSize = m_list.at(2).toULongLong();
        passphraseAlian = m_list.last();
        if(QFile::exists(filePath)) {
            qDebug(logClient()) << "File already exists!";
            QFile::remove(filePath);
        }
        file = new QFile(filePath);
        QStringList entryInfo = QString(m_list.first()).split('|');
        if(!file->open(QFile::Append)) {
            qCritical(logClient()) << "Cannot open file"; 
            closeHost(RequestType::TYPE_ERROR_OPEN_FILE);
        }
        else
            emit startOperationFile(true, entryInfo.first(), entryInfo.last());
        return;
    }
    if(request == Status::ERROR_EXISTS_FILE) {
        qCritical(logClient()) << "Cookies ERROR";
        closeHost(RequestType::TYPE_ERROR_EXISTS_FILE);
        return;
    }
    if(request == Status::ERROR_FILE) {
        qCritical(logClient()) << "Error file";
        closeHost(RequestType::TYPE_SOMEERROR);
        return;
    }

    if(request == Status::ERROR_SIZE_FILE) {            //найти применение
        qCritical(logClient()) << "Error file size";
        closeHost(RequestType::TYPE_SOMEERROR);
        return;
    }
}

void Client::slotDisconnected() {
qDebug(logClient()) << "Disconnected";
    cWrapper.freeRSAKey(publickey);
}

void Client::closeHost(int mode) {
qDebug(logClient()) << "Close mode:" << mode;
    if(mode != RequestType::TYPE_WRONGIP) {
        m_socket->disconnectFromHost();
    }
    emit finished(mode);
    deleteLater();
}

//void Client::slotError(QAbstractSocket::SocketError error) {
//    QString strError =
//        ": Error: " + (error == QAbstractSocket::HostNotFoundError ?
//                     "The host was not found." :
//                     error == QAbstractSocket::RemoteHostClosedError ?
//                     "The remote host is closed." :
//                     error == QAbstractSocket::ConnectionRefusedError ?
//                     "The connection was refused." :
//                     QString(m_socket->errorString())
//                    );
//    qCritical(logClient()) << strError;
//}

Client::~Client() {
qDebug(logClient()) << "Destroyed";
    delete m_socket;
}
