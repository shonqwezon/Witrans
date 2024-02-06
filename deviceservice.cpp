#include "deviceservice.h"

DeviceService::DeviceService(QObject *parent) : QObject(parent) {
qDebug(logDeviceService()) << "Initializated";
}

QByteArray DeviceService::generateBaseCode() {
    basePass = cipher.randomBytes(4).toBase64();
//qDebug(logDeviceService()) << "Base passphrase:" << basePass;
    return basePass;
}

QByteArray DeviceService::getBaseCode() {
    return basePass;
}

bool DeviceService::checkIp(QString ip) {
    return hash.contains(ip);
}

DeviceService::~DeviceService() {
    qDebug(logDeviceService()) << "Destroyed";
}

void DeviceService::closeSession() {
qDebug(logDeviceService()) << "Close session...";
    for(QString ip : hash.keys()) emit disconnectedOldDevice(ip);
    if(!receiversList.isEmpty()) emit deactivateTab();
    receiversList.clear();
    hash.clear();
    cookies.clear();
}

QByteArray DeviceService::getPassphrase() {
    QByteArray suffixPass = cipher.randomBytes(4).toBase64();
    return basePass + suffixPass;
}

QByteArray DeviceService::getName() {
    QString name = Registry::getName();
    return name.toUtf8();
}

void DeviceService::setValue(QString ip, QList<QString> values) {
    if(hash.contains(ip)) {
qDebug(logDeviceService()) << "Contains this device";
        QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8);
        QString username = getValue(ip, HashType::TYPE_USERNAME);
        disconnectedDevice(ip, baseCode);
        emit newNotification("error", ip + " уже существует", QTime::currentTime().toString("hh:mm:ss"));
    }
    foreach(QString value, values) hash.insert(ip, value);
//qDebug(logDeviceService()) << "Hash:" << hash.values(ip);
    emit connectedNewDevice(ip, values);
}

void DeviceService::askData(bool download, QString type, QString ip, QString size, QList<QVector<QString>> askingData) {
    QString user = getValue(ip, HashType::TYPE_USERNAME);
    emit newRequestData(download, type, ip, user, size, askingData);
}

QString DeviceService::getValue(QString ip, qsizetype type) {
    QString value = "";
//qDebug(logDeviceService()) << "Hash values:" << hash.values(ip) << type;
    if(!hash.values(ip).isEmpty()) {
        value = hash.values(ip).at(type);
    }
    return value;
}

QString DeviceService::getFilePath(QString ipToken, QString fileId) {
    QHash<QString, QString> files = cookies.value(ipToken);
    QString filePath = files.take(fileId);
    if(files.isEmpty()) cookies.remove(ipToken);
    else cookies.insert(ipToken, files);
    return filePath;
}

void DeviceService::deleteCookie(QString ipToken, QString fileId) {
    if(fileId.isEmpty()) cookies.remove(ipToken);
    else {
        QHash<QString, QString> files = cookies.value(ipToken);
        files.remove(fileId);
        if(files.isEmpty()) cookies.remove(ipToken);
        else cookies.insert(ipToken, files);
    }
}

void DeviceService::disconnectedDevice(QString ip, QString code) {
qDebug(logDeviceService()) << Q_FUNC_INFO << "Disconnected" << ip;
    QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8); //alianPassphrase
qDebug(logDeviceService()) << "baseCode << code";
    if(baseCode == code) {
qDebug(logDeviceService()) << "cookies start size:" << cookies.size();
        for(QString key : cookies.keys()) { if(key.startsWith(ip)) cookies.remove(key); }
qDebug(logDeviceService()) << "cookies end size:" << cookies.size();
        removeReceiver(ip);
        emit disconnectedOldDevice(ip); //name << mode << id << localPassphrase << alianPassphrase << index;
        hash.remove(ip);
qDebug(logDeviceService()) << "Device was confirmed";
    }
    else qDebug(logDeviceService()) << "Device was not confirm";
}

void DeviceService::connectedDevice(QString ip, QString code) {
qDebug(logDeviceService()) << Q_FUNC_INFO << "Connected" << ip;

    QList<QString> info = database.getOfConnecting(code);
    if(!info.isEmpty()) {
qDebug(logDeviceService()) << "Device was verifyied";
        QString name = info.at(0);
        QString mode = info.at(1);
        QString id_device = info.at(2);
        QString key = info.at(3);

qDebug(logDeviceService()) << "Information from database:"; //<< name << mode << id_device << key.size();

        Client *client = new Client(PacketType::TYPE_OLDFRIEND, key, getPassphrase(), QHostAddress(ip));
        QThread *threadClient = new QThread();
        QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
        QObject::connect(client, &Client::saveToHash, this, [this, name, mode, id_device](QList<QString> infoClient) {
            QList<QString> m_infoClient = infoClient;
            QString ip = m_infoClient.takeFirst();
            m_infoClient.prepend(id_device);
            m_infoClient.prepend(mode);
            m_infoClient.prepend(name);
qDebug(logDeviceService()) << "Registration of the old friend:" << "ip << m_infoClient";
            setValue(ip, m_infoClient);
        });
        QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
        QObject::connect(client, &Client::finished, this, [](int requestMode) { qDebug(logDeviceService()) << "Finished code of connecting:" << requestMode; });
        QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
        QObject::connect(threadClient, &QThread::destroyed, this, [](){qDebug(logDeviceService()) << "Thread of client destroyed";});
        client->moveToThread(threadClient);
        threadClient->start();
    }
}

QList<QString> DeviceService::getInfoOldClient(QString id) {
qDebug(logDeviceService()) << Q_FUNC_INFO << "id";
    return database.getOfOldFriend(id);
}

void DeviceService::deleteDevice(QString ip) {
qDebug(logDeviceService()) << "Deleted client:" << ip;
    QString id_device = getValue(ip, HashType::TYPE_ID);
    QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8);
qDebug(logDeviceService()) << "Id:" << "id_device";
    disconnectedDevice(ip, baseCode);
    database.deleteEntry(id_device);
}

bool DeviceService::sendDeleteDevice(QString ip) {
qDebug(logDeviceService()) << "Deleted client:" << ip;
    QString id_device = getValue(ip, HashType::TYPE_ID);
qDebug(logDeviceService()) << "Id:" << "id_device";
if(!database.deleteEntry(id_device)) return false;
    Client *client = new Client(PacketType::TYPE_DELETE, NULL, NULL, QHostAddress(ip));
    QThread *threadClient = new QThread();
    QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
    QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
    QObject::connect(client, &Client::finished, this, [this, ip](int requestMode){
qDebug(logDeviceService()) << "Finished code of removing:" << requestMode;
        QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8);
        disconnectedDevice(ip, baseCode);
        if(requestMode == RequestType::TYPE_WRONGIP || requestMode == RequestType::TYPE_SOMEERROR) {
qDebug(logDeviceService()) << "Device dead";
            QString username = getValue(ip, HashType::TYPE_USERNAME);
            emit newNotification("error", username + " невозможно удалить", QTime::currentTime().toString("hh:mm:ss"));

        }
    });
    QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
    QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });
    client->moveToThread(threadClient);
    threadClient->start();
    return true;
    //name << mode << id << localPassphrase << alianPassphrase;
}

bool DeviceService::renameDevice(QString ip, QString nickname) {
qDebug(logDeviceService()) << "Rename client:" << ip << "- new name:" << nickname;
    QString id_device = getValue(ip, HashType::TYPE_ID);
    QList<QString> currentList = hash.values(ip);
    hash.remove(ip);
    currentList.replace(HashType::TYPE_USERNAME, nickname);
    for(int i = currentList.size()-1; i > -1; i--) hash.insert(ip, currentList.at(i));
qDebug(logDeviceService()) << Q_FUNC_INFO << "New hash:" << "hash.values(ip)";
    return database.renameDeviceName(id_device, nickname);
}

void DeviceService::addReceiver(QString ip) {
qDebug(logDeviceService()) << Q_FUNC_INFO << ip;
    receiversList.append(ip);
    if(receiversList.count() == 1) {
qDebug(logDeviceService()) << Q_FUNC_INFO << "can be sent";
        emit activateTab();
    }
}

void DeviceService::removeReceiver(QString ip) {
qDebug(logDeviceService()) << Q_FUNC_INFO << ip;
    if(!receiversList.isEmpty()) {
        receiversList.remove(receiversList.indexOf(ip));
        if(receiversList.isEmpty()) {
qDebug(logDeviceService()) << Q_FUNC_INFO << "empty";
            emit deactivateTab();
        }
    }
}

void DeviceService::clearReceiver() {
qDebug(logDeviceService()) << Q_FUNC_INFO;
    receiversList.clear();
    emit deactivateTab();
}

bool DeviceService::cancelRequest(QString ip, QString token, QString id) {
    qDebug(logDeviceService()) << "cancelRequest:" << ip << token << id;
    deleteCookie(ip+token, id);
    QByteArray passphrase = getValue(ip, HashType::TYPE_LOCAL_PASS).toLatin1();
    QString data =  token + "|" + id;
    Client *client = new Client(PacketType::TYPE_CANCEL_REQUEST, data, passphrase, QHostAddress(ip));
    QThread *threadClient = new QThread();
    QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
    QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
    QObject::connect(client, &Client::finished, this, [this, ip](int requestMode){
        if(requestMode == RequestType::TYPE_WRONGIP) {
qDebug(logDeviceService()) << "Device dead";
            QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8);
            QString username = getValue(ip, HashType::TYPE_USERNAME);
            disconnectedDevice(ip, baseCode);
            emit newNotification("error cancel", username + " недоступен", QTime::currentTime().toString("hh:mm:ss"));
            return;
        }
    });
    QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
    QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });
    client->moveToThread(threadClient);
    threadClient->start();
    return true;
}

void DeviceService::sendText(QString text) {
    QList<QString> currentReceivers = receiversList;
qDebug(logDeviceService()) << "Send text:" << "text << currentReceivers";
    for(QString userIp : currentReceivers) {
qDebug(logDeviceService()) << "Sending to" << "userIp";
        QByteArray passphrase = getValue(userIp, HashType::TYPE_LOCAL_PASS).toLatin1();
        Client *client = new Client(PacketType::TYPE_MSG, text, passphrase, QHostAddress(userIp));
        QThread *threadClient = new QThread();
        QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
        QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
        QObject::connect(client, &Client::finished, this, [this, userIp](int requestMode) {
qDebug(logDeviceService()) << "Finished code of sending text:" << requestMode;
            if(requestMode == RequestType::TYPE_WRONGIP) {
qDebug(logDeviceService()) << "Device dead";
                QString baseCode = getValue(userIp, HashType::TYPE_ALIAN_PASS).left(8);
                QString username = getValue(userIp, HashType::TYPE_USERNAME);
                disconnectedDevice(userIp, baseCode);
                emit newNotification("error", username + " недоступен", QTime::currentTime().toString("hh:mm:ss"));
            }
        });
        QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
        QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });
        client->moveToThread(threadClient);
        threadClient->start();
    }
}

void DeviceService::acceptFile(QString ip, QString token, QString id, QString fileName, QString realSize) {
    qDebug(logDeviceService()) << ip << token << id << fileName << realSize;
    QList<QByteArray> cookieInfo;
    cookieInfo << (token+"|"+id).toUtf8() << fileName.toUtf8() << realSize.toUtf8() << getValue(ip, HashType::TYPE_ALIAN_PASS).toLatin1();
    QByteArray passphrase = getValue(ip, HashType::TYPE_LOCAL_PASS).toLatin1();
    Client *client = new Client(PacketType::TYPE_ACCEPT_FILE, cookieInfo, passphrase, QHostAddress(ip));
    QThread *threadClient = new QThread();
    QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
    QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
    QObject::connect(client, &Client::finished, this, [this, ip, fileName, token, id](int requestMode) {
qDebug(logDeviceService()) << "Finished code of sending information of files:" << requestMode;
        switch(requestMode) {
            case RequestType::TYPE_ERROR_EXISTS_FILE:
qDebug(logDeviceService()) << "Sender doesn't have file!";
                emit newNotification("error", fileName + " недоступен", QTime::currentTime().toString("hh:mm:ss"));
                emit deleteIrrelevantFile(true, ip, token, id);
                break;
            case RequestType::TYPE_WRONGIP:
qDebug(logDeviceService()) << "Device dead";
                QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8);
                QString username = getValue(ip, HashType::TYPE_USERNAME);
                disconnectedDevice(ip, baseCode);
                emit newNotification("error", username + " недоступен", QTime::currentTime().toString("hh:mm:ss"));
                break;
        }
    });
    QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
    QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });

    QObject::connect(client, &Client::startOperationFile, this, &DeviceService::startOperationFile);
    QObject::connect(client, &Client::changedProgress, this, &DeviceService::changedProgress);
    QObject::connect(client, &Client::endDownloadFile, this, &DeviceService::endDownloadFile);

    QObject::connect(this, &DeviceService::stopDownloadFile, client, &Client::stopDownloadFile);
    client->moveToThread(threadClient);
    threadClient->start();
}

void DeviceService::rejectFile(QString ip, QString token, QString id) {
    qDebug(logDeviceService()) << ip << token << id;
    QByteArray passphrase = getValue(ip, HashType::TYPE_LOCAL_PASS).toLatin1();
    Client *client = new Client(PacketType::TYPE_REJECT_FILE, token+"|"+id, passphrase, QHostAddress(ip));
    QThread *threadClient = new QThread();
    QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
    QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
    QObject::connect(client, &Client::finished, this, [this, ip](int requestMode) {
qDebug(logDeviceService()) << "Finished code of sending information of files:" << requestMode;
        if(requestMode == RequestType::TYPE_WRONGIP) {
qDebug(logDeviceService()) << "Device dead";
            QString baseCode = getValue(ip, HashType::TYPE_ALIAN_PASS).left(8);
            QString username = getValue(ip, HashType::TYPE_USERNAME);
            disconnectedDevice(ip, baseCode);
            emit newNotification("error", username + " недоступен", QTime::currentTime().toString("hh:mm:ss"));
        }
    });
    QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
    QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });
    client->moveToThread(threadClient);
    threadClient->start();
}

void DeviceService::requestFiles(QHash<QString, QString> files) {
    QList<QString> currentReceivers = receiversList;
    QList<QByteArray> list;
    QList<QVector<QString>> askList;
    qint64 totalFileSize = 0;
    QHash<QString, QString> keyFiles;
    for(QString path : files.keys()) {
        QFileInfo fileInfo(path);
        qint64 sizeFile = fileInfo.size();
        totalFileSize += sizeFile;
        QString key = QString::number(QRandomGenerator::global()->generate());
        keyFiles.insert(key, path);
        list.append((key + "|" + fileInfo.suffix() + "|" + files.value(path) + '|' + QString::number(sizeFile)).toUtf8());
        askList.append({ key, fileInfo.suffix(), files.value(path), QString::number(sizeFile), GuiService::convertSize(sizeFile), path});
    }
    for(QString userIp : currentReceivers) {
        QByteArray token = cipher.randomBytes(Config::sizeToken).toBase64();
        list.prepend(token);
        askList.prepend({ token });
        cookies.insert(userIp + token, keyFiles); //разные токены на файлы

        QByteArray passphrase = getValue(userIp, HashType::TYPE_LOCAL_PASS).toLatin1();
        Client *client = new Client(PacketType::TYPE_REQUEST_FILE, list, passphrase, QHostAddress(userIp));
        QThread *threadClient = new QThread();
        QObject::connect(threadClient, &QThread::started, client, &Client::startClient);
        QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
        QObject::connect(client, &Client::finished, this, [this, userIp, askList, totalFileSize](int requestMode) {
qDebug(logDeviceService()) << "Finished code of sending information of files:" << requestMode;
            if(requestMode == RequestType::TYPE_WRONGIP) {
qDebug(logDeviceService()) << "Device dead";
                QString baseCode = getValue(userIp, HashType::TYPE_ALIAN_PASS).left(8);
                QString username = getValue(userIp, HashType::TYPE_USERNAME);
                disconnectedDevice(userIp, baseCode);
                emit newNotification("error", username + " недоступен", QTime::currentTime().toString("hh:mm:ss"));
                return;
            }
            if(requestMode == RequestType::TYPE_ACCEPT_COOKIES) {
                QString type = askList.size() == 2 ? "file" : "files";
                askData(false, type, userIp, GuiService::convertSize(totalFileSize), askList);
                return;
            }
        });
        QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
        QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });
        client->moveToThread(threadClient);
        threadClient->start();
    }
}

bool DeviceService::registryFromServer(QList<QString> infoClient) {
qDebug(logDeviceService()) << Q_FUNC_INFO;
    return database.registryClient(infoClient);
}

QString DeviceService::getCode() {
    updateCode();
    QString code = getLocalIp(true);
    code += currentCode;
    return code;
}

void DeviceService::updateCode() {
    currentCode = cipher.randomBytes(8).toBase64();
qDebug(logDeviceService()) << "Passphrase:"; //<< currentCode;
}

QString DeviceService::getLocalIp(bool convert) {
    QString ip = "";

    PIP_ADAPTER_INFO pAdapterInfo;
    pAdapterInfo = (IP_ADAPTER_INFO *) malloc(sizeof(IP_ADAPTER_INFO));
    ULONG buflen = sizeof(IP_ADAPTER_INFO);

    if(GetAdaptersInfo(pAdapterInfo, &buflen) == ERROR_BUFFER_OVERFLOW) {
        free(pAdapterInfo);
        pAdapterInfo = (IP_ADAPTER_INFO *) malloc(buflen);
    }

    if(GetAdaptersInfo(pAdapterInfo, &buflen) == NO_ERROR) {
        PIP_ADAPTER_INFO pAdapter = pAdapterInfo;
        while (pAdapter) {
            if(pAdapter->DhcpEnabled) {
                ip = pAdapter->IpAddressList.IpAddress.String;
                qDebug() << "\n";
                qDebug() << "\tAdapter Type:" << pAdapter->Type;
                qDebug() << "\tAdapter Name:" << pAdapter->AdapterName;
                qDebug() << "\tAdapter Desc:" << pAdapter->Description;
                qDebug() << "\tAdapter Addr:" << pAdapter->Address;
                qDebug() << "\tIP Address:" << ip;
                qDebug() << "\tIP Mask:" << pAdapter->IpAddressList.IpMask.String;
                qDebug() << "\tGateway:" << pAdapter->GatewayList.IpAddress.String;
                qDebug() << "\n";
                if(ip != "0.0.0.0") break;
            }
            pAdapter = pAdapter->Next;
        }
    }
    else {
        qDebug(logDeviceService()) << "Call to GetAdaptersInfo failed.";
    }

    if(convert && !ip.isEmpty()) {
        QStringList bytes  = ip.split('.');
        ip.clear();

        foreach(QString byte, bytes) {
            int n = byte.toUInt();
            if(n < 10) ip += "0";
            ip += QString::number(n, 16).toLower();
        }
    }

    return ip;
}

QByteArray DeviceService::getCurrentCode() {
    return currentCode;
}

void DeviceService::requestDevice(QString code) {
    if(code.left(8) == getLocalIp(true)) {
qDebug(logDeviceService()) << "IP is local";
        emit responseDevice(RequestType::TYPE_LOCALIP);
        return;
    }

    QString name = Registry::getName();
    QByteArray mode = code.right(1).toUtf8();
    code.chop(1);
    QList<QByteArray> dataClient = { code.right(12).toLatin1() };
    code.chop(12);
    bool ok;
    QHostAddress address = QHostAddress(code.toUInt(&ok, 16));
//qDebug(logDeviceService()) << "address" << ok;
//qDebug(logDeviceService()) << "name" << name;
//qDebug(logDeviceService()) << "request IP:" << code << address.toString();
//qDebug(logDeviceService()) << "request passphrase:" << passphrase;
//qDebug(logDeviceService()) << "request mode:" << mode;

    dataClient.append((name + mode).toLatin1());

    if(hash.contains(address.toString())) {
qDebug(logDeviceService()) << "Device has added already";
       emit responseDevice(RequestType::TYPE_EXIST);
       return;
    }

    Client *client = new Client(PacketType::TYPE_KEYADD, dataClient, getPassphrase(), address);
    QThread *threadClient = new QThread();
    QObject::connect(threadClient, &QThread::started, client, &Client::startClient);

    QObject::connect(client, &Client::saveToBase, this, [this](QList<QString> infoClient) {
        QList<QString> m_infoClient = infoClient;
qDebug(logDeviceService()) << "Registration from client";
        database.registryClient(m_infoClient);

        QString id = infoClient.at(3);
        QString ip = infoClient.at(0);
        QString name = infoClient.at(1);
        QString mode = name.right(1);
        name.chop(1);
        QString localPassphrase = infoClient.at(4);
        QString alianPassphrase = infoClient.at(5);
        QList<QString> values;
        values << name << mode << id << localPassphrase << alianPassphrase;
        setValue(ip, values);
    });
    QObject::connect(client, &Client::finished, threadClient, &QThread::quit);
    QObject::connect(client, &Client::finished, this, &DeviceService::responseDevice);
    QObject::connect(threadClient, &QThread::finished, threadClient, &QThread::deleteLater);
    QObject::connect(threadClient, &QThread::destroyed, this, [](){ qDebug(logDeviceService()) << "Thread of client destroyed"; });
    client->moveToThread(threadClient);
    threadClient->start();
}
