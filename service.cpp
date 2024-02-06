#include "service.h"

Service::Service(DeviceService &deviceService, QObject* parent) : QObject(parent), m_deviceService(deviceService) {
qDebug(logService()) << "Initializated";
    QCryptographicHash md5(QCryptographicHash::Md5);
    md5.addData(deviceID.toUtf8());
    hash = md5.result();

    broadcastSocket.bind(QHostAddress::Any, Port::broadcast);
    QObject::connect(&broadcastSocket, &QUdpSocket::readyRead, this, &Service::readyReadBroadcast);
    openSession();
}

Service::~Service() {
    qDebug(logService()) << "Destroyed";
}

void Service::openSession() {
    localIp = m_deviceService.getLocalIp();
    if(localIp.isEmpty()) {
        qDebug(logService()) << "Getting local ip...";
        QTimer::singleShot(10000, this, &Service::openSession);
    }
    else {
        qDebug(logService()) << "Local ip was got:" << localIp;

        broadcastIp = QHostAddress(localIp.left(localIp.lastIndexOf('.')).append(".255"));

        goodbye = m_deviceService.generateBaseCode();

        qDebug(logService()) << "Sending message:" << hash.toHex() << "to" << broadcastIp.toString();
        broadcastSocket.writeDatagram(hash, broadcastIp, Port::broadcast);
        if(broadcastSocket.error() != QAbstractSocket::UnknownSocketError) qDebug(logService()) << broadcastSocket.errorString();
    }
}

void Service::readyReadBroadcast() {
    QByteArray buffer;
    buffer.resize(broadcastSocket.pendingDatagramSize());

    QHostAddress sender;
    quint16 senderPort;

    broadcastSocket.readDatagram(buffer.data(), buffer.size(), &sender, &senderPort);

    if(QHostAddress(sender.toIPv4Address()) != QHostAddress(localIp)) {
        QString ip = QHostAddress(sender.toIPv4Address()).toString();
qDebug(logService()) << "Get message from" << ip << ":" << buffer.toHex();
        if(buffer.toHex().size() == 16) {
            m_deviceService.disconnectedDevice(ip, buffer);
        }
        else {
            m_deviceService.connectedDevice(ip, buffer.toHex());
        }
    }
}

void Service::closeSession() {
qDebug(logService()) << "Close event app";
    if(!goodbye.isEmpty() && !broadcastIp.toString().isEmpty()) {
        m_deviceService.closeSession();
        broadcastSocket.writeDatagram(goodbye, broadcastIp, Port::broadcast);
        goodbye.clear();
        broadcastIp.clear();
    }
}


