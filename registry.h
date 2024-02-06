#ifndef REGISTRY_H
#define REGISTRY_H

#include <QDebug>
#include <QObject>
#include <QSettings>
#include <QString>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QMultiHash>
#include "config.h"
#include "guiservice.h"

#include "loggingcategories.h"

class Registry : public QObject
{
    Q_OBJECT
public:
    explicit Registry(QObject *parent = nullptr);
    ~Registry();

    static QByteArray getDeviceId();
    static QString getName();
    static QMultiHash<QString, unsigned long> getSequences();
    static QString getDownloadPath();

public slots:
    void setLogin(const QString& login);
    QString getLogin() const;

    void setAvatar(QString pathAvatar);
    QString getAvatar() const;

    void setKeyBind(int modifier, int key);
    QString getKeyBind() const;

    void setMinimized(bool minimized);
    bool getMinimized() const;

    void setAutopaste(bool autopaste);
    bool getAutopaste() const;

    void setDefaultPath(QString path);
    QString getDefaultPath() const;

signals:
    void changedLogin();
    void changedAvatar();

private:
    QString appPath = QCoreApplication::applicationDirPath()+QDir::separator();
    QSettings *registry;
    QString m_pathAvatar;
    QString loginDefault;
    QString pathAvatarDefault = "qrc:/icons/icons/defaultUser.png";
};

#endif // REGISTRY_H
