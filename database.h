#ifndef DATABASE_H
#define DATABASE_H

#include <QFileInfo>
#include <QDebug>
#include <QThread>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QList>
#include <QCryptographicHash>
#include <QDir>
#include <QCoreApplication>
#include <windows.h>

#include "loggingcategories.h"
#include "config.h"
#include <QMutex>


class Database
{
public:
    explicit Database();

public slots:
    QList<QString> getOfConnecting(QString hash);
    QList<QString> getOfOldFriend(QString id);
    bool deleteEntry(QString id);
    bool renameDeviceName(QString id, QString nickname);
    bool registryClient(QList<QString> infoClient);

private:
    QSqlDatabase db;
    QMutex mutex;
    QString dbPath = QCoreApplication::applicationDirPath() + QDir::separator() + DataBase::dbName;
};

#endif // DATABASE_H
