#ifndef SERVER_H
#define SERVER_H

#include <QObject>
#include <QtNetwork>
#include <QThread>
#include <QDebug>
#include <QHash>
#include "socketthread.h"
#include "config.h"
#include "deviceservice.h"

#include "loggingcategories.h"

class Server : public QTcpServer
{
    Q_OBJECT
public:
    explicit Server(DeviceService &deviceService, QHostAddress host = QHostAddress::Any, quint16 port = Port::tcp, QObject *parent = nullptr);
    ~Server();

    void startServer();

protected:
    void incomingConnection(qintptr handle);

signals:
    void changedCode();
    void stopUploadFile(QString ip, QString token, QString id);

private:
    DeviceService &m_deviceService;

    QHostAddress m_host;
    quint16 m_port;
};

#endif // SERVER_H
