#ifndef SERVICE_H
#define SERVICE_H

#include <QObject>
#include <QDebug>
#include <QUdpSocket>
#include "config.h"
#include "deviceservice.h"
#include <QCryptographicHash>
#include <QTimer>
#include "registry.h"

#include "loggingcategories.h"

class Service : public QObject
{
    Q_OBJECT

public:
    explicit Service(DeviceService &deviceService, QObject* parent = nullptr);
    ~Service();

    void closeSession();

public slots:
    void openSession();

private slots:
    void readyReadBroadcast();

private:
    QString localIp;

    QHostAddress broadcastIp;
    QByteArray hash;

    DeviceService &m_deviceService;
    QUdpSocket broadcastSocket;
    QString deviceID = Registry::getDeviceId();

    QByteArray goodbye;
};

#endif // SERVICE_H
