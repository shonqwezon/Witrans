#ifndef SOCKETTHREAD_H
#define SOCKETTHREAD_H

#include <QObject>
#include <QtNetwork>
#include <QFile>
#include <QDebug>
#include <QList>
#include <QTime>
#include <QTimer>

#include "cipher.h"
#include "config.h"
#include "registry.h"
#include "deviceservice.h"

#include "loggingcategories.h"

class SocketThread : public QObject
{
    Q_OBJECT
public:
    explicit SocketThread(DeviceService &deviceService, qintptr socketDescription, QObject *parent = nullptr);
    ~SocketThread();

    void startSocketThread();

signals:
    void finished();
    void changeCode();
    void acceptMessage(QByteArray text);

public slots:
    void stopUploadFile(QString ip, QString token, QString id);

private slots:
    void slotUnknownDevice();

    void slotReadyRead();
    void sendPartOfFile();
    void slotDisconnected();

    bool sendResponse(const QByteArray status);

private:
    Cipher cWrapper;

    DeviceService &m_deviceService;
    qintptr m_socketDescription;

    RSA* privatekey = nullptr;
    QTcpSocket *m_socket;
    int packetType;
    QString hostIp;

    QList<QString> infoClient; //ip, alianName, alianPubKey, alianId, localPass, alianPass
    QByteArray encryptedPassphrase = ""; //passphrase (baseCode8 + suffix8)

    QByteArray passphraseAlian;
    int permissionMode;

    QByteArray decryptedPlain;

    QString p_fileId;
    QString p_fileToken;
    QTime timeStart;

    QByteArray localPassphrase;
    int countSendFile = 0;
    qint64 sizeSentData = 0;
    QFile *file;
};

#endif // SOCKETTHREAD_H
