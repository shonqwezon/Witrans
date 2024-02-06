#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QtNetwork>
#include <QFile>
#include <QHash>
#include <QDebug>
#include <QTime>
#include <QTimer>
#include "cipher.h"
#include "registry.h"
#include "config.h"
#include <iostream>

#include "loggingcategories.h"

class Client : public QObject
{
    Q_OBJECT

public:
    explicit Client(int typeData, QString data, QByteArray passphrase, QHostAddress host, quint16 port = Port::tcp, QObject *parent = nullptr);
    explicit Client(int typeData, QList<QByteArray> list, QByteArray passphrase, QHostAddress host, quint16 port = Port::tcp, QObject *parent = nullptr);
    ~Client();

signals:
    void finished(int mode);
    void saveToBase(QList<QString> infoClient);
    void saveToHash(QList<QString> infoClient);

    void acceptFile(QString fileName);

    void startOperationFile(bool download, QString token, QString id);
    void changedProgress(bool download, QString token, QString id, int progressStatus);
    void endDownloadFile(QString token, QString id, QString time, QString filePath);

public slots:
    void startClient();
    void stopDownloadFile(QString ip, QString token, QString id);

private slots:
    void slotDisconnected();
    void slotReadResponse();
    void slotReadKey();
    void slotConnected();

    void sendPersonalInfo(bool mode);

    void getPartOfFile();
//    void slotError(QAbstractSocket::SocketError error);

    void closeHost(int mode);

private:
    Cipher cWrapper;

    int m_typeData;
    QString m_data;
    QList<QByteArray> m_list;
    QByteArray m_passphrase;
    QHostAddress m_host;
    quint16 m_port;

    QTcpSocket *m_socket;

    RSA* publickey = NULL;
    QList<QString> infoClient; //ip, alianName, alianPubKey, alianId, localPass, alianPass
    QString hostIp;

    QByteArray tempBytes{};
    QTime timeStart;
    qint64 fileSize;
    QFile *file;

    int countGetFile = 0;
    QByteArray passphraseAlian;
    qint64 sizeReceivedData = 0;
    int fail = 0;
};

#endif // CLIENT_H
