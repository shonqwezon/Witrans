#ifndef DEVICESERVICE_H
#define DEVICESERVICE_H

#include <QObject>
#include <QHostAddress>
#include <QNetworkInterface>
#include <QAbstractSocket>
#include <QDebug>
#include <QThread>
#include <QMultiHash>
#include <QList>
#include <QTime>
#include <QRandomGenerator>

#include <iphlpapi.h>
#include <winsock2.h>

#include "cipher.h"
#include "client.h"
#include "registry.h"
#include "guiservice.h"

#include "loggingcategories.h"
#include "database.h"

class DeviceService : public QObject
{
    Q_OBJECT
public:
    QHash<QString, QHash<QString, QString>> cookies; //соответсвие токена (ip + token) файлам

    explicit DeviceService(QObject *parent = nullptr);
    ~DeviceService();

    void closeSession();

    QByteArray generateBaseCode();

    QByteArray getCurrentCode();
    QByteArray getPassphrase();
    QByteArray getName();

    void setValue(QString ip, QList<QString> values);
    QString getValue(QString ip, qsizetype type);

    QString getFilePath(QString ipToken, QString fileId);
    void deleteCookie(QString ipToken, QString fileId);

    void askData(bool download, QString type, QString ip, QString size, QList<QVector<QString>> askingData);

    QString getLocalIp(bool convert = false);
    QByteArray getBaseCode();
    bool checkIp(QString ip);

    void deleteDevice(QString ip);

signals:
    void connectedNewDevice(QString ip, QList<QString> list);
    void disconnectedOldDevice(QString ip);
    void responseDevice(int response);

    void activateTab();
    void deactivateTab();

    void newRequestData(bool download, QString type, QString ip, QString user, QString size, QList<QVector<QString>> askingData);
    void deleteIrrelevantFile(bool download, QString ip, QString token, QString id);

    void timeoutRequestData(QString handle);

    void newNotification(QString type, QString body, QString time);

    void startOperationFile(bool download, QString token, QString id);
    void changedProgress(bool download, QString token, QString id, int progressStatus);
    void endDownloadFile(QString token, QString id, QString time, QString filePath);

    void stopDownloadFile(QString ip, QString token, QString id);

public slots:
    QString getCode();
    void requestDevice(QString code);
    bool registryFromServer(QList<QString> infoClient);
    void disconnectedDevice(QString ip, QString code);
    void connectedDevice(QString ip, QString code);
    QList<QString> getInfoOldClient(QString id);

    bool sendDeleteDevice(QString ip);
    bool renameDevice(QString ip, QString nickname);

    void addReceiver(QString ip);
    void removeReceiver(QString ip);
    void clearReceiver();

    bool cancelRequest(QString ip, QString token, QString id);

    void sendText(QString text);
    void requestFiles(QHash<QString, QString> files);
    void acceptFile(QString ip, QString token, QString id, QString fileName, QString realSize); //get file / files
    void rejectFile(QString ip, QString token, QString id);

private slots:
    void updateCode();

private:
    Database database;

    Cipher cipher;
    QByteArray currentCode;

    QByteArray basePass;

    QMultiHash<QString, QString> hash; //name << mode << id << localPassphrase << alianPassphrase;
    QList<QString> receiversList;

    //шифруем своим шифром
};

#endif // DEVICESERVICE_H
