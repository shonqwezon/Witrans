#include "server.h"

Server::Server(DeviceService &deviceService, QHostAddress host, quint16 port, QObject *parent)
    : QTcpServer(parent), m_deviceService(deviceService),
      m_host(host), m_port(port)
{
qDebug(logServer()) << "Initializated";
}

void Server::startServer() {
qDebug(logServer()) << "Server started";
    if(!this->listen(m_host, m_port)) {
        qCritical(logServer()) << "Server could not start";
    }
}

void Server::incomingConnection(qintptr handle) {
qDebug(logServer()) << "Incoming connection =" << handle;
    SocketThread *socketThread = new SocketThread(m_deviceService, handle);
    QObject::connect(socketThread, &SocketThread::changeCode, this, &Server::changedCode);

    QThread *thread = new QThread();
    QObject::connect(thread, &QThread::started, socketThread, &SocketThread::startSocketThread);
    QObject::connect(socketThread, &SocketThread::finished, thread, &QThread::quit);
    QObject::connect(socketThread, &SocketThread::finished, socketThread, &SocketThread::deleteLater);
    QObject::connect(thread, &QThread::finished, thread, &QThread::deleteLater);
    QObject::connect(thread, &QThread::destroyed, this, [](){ qDebug(logServer()) << "Thread of socket destroyed"; });
    QObject::connect(socketThread, &SocketThread::acceptMessage, this, [](QByteArray text){ QGuiApplication::clipboard()->setText(text); });

    QObject::connect(this, &Server::stopUploadFile, socketThread, &SocketThread::stopUploadFile);
    socketThread->moveToThread(thread);
    thread->start();
}

Server::~Server() {
qDebug(logServer()) << "Destroyed";
}
