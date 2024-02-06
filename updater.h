#ifndef UPDATER_H
#define UPDATER_H

#include <QObject>
#include <QProcess>
#include <QDebug>
#include <QDir>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QGuiApplication>
#include <windows.h>
#include "cipher.h"
#include "registry.h"
#include "config.h"

#include "loggingcategories.h"

class Updater : public QObject
{
    Q_OBJECT
public:
    explicit Updater(QString v = QGuiApplication::applicationVersion(), QObject* parent = nullptr);
    ~Updater();

public slots:
    void checkUpdate();
    QString getCurrentVersion() const;

private slots:
    void some_error(QString error);

private:
    QString version;
    QNetworkAccessManager *manager;
};

#endif // UPDATER_H
