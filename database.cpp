#include "database.h"

Database::Database() {
qDebug(logDatabase()) << "Initializated";
    db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(dbPath);
    if(!QFileInfo::exists(dbPath)) {
        qCritical(logDatabase()) << "Database doesn't exist";
        if(!db.open()) {
            qCritical(logUpdater()) << "Database:" << db.lastError().text();
            MessageBoxA(NULL, db.lastError().text().toStdString().c_str(), "Witrans's database", MB_ICONERROR);
            QCoreApplication::exit(EXIT_FAILURE);
        }
        QSqlQuery query(db);
        if(!query.exec("CREATE TABLE Accounts(id INTEGER PRIMARY KEY AUTOINCREMENT, id_device TEXT, hash TEXT, key TEXT, name TEXT, mode TEXT);")) {
            qCritical(logUpdater()) << "Database:" << db.lastError().text();
            MessageBoxA(NULL, db.lastError().text().toStdString().c_str(), "Witrans's database", MB_ICONERROR);
            QCoreApplication::exit(EXIT_FAILURE);
        }
        db.close();
    }
}

QList<QString> Database::getOfConnecting(QString hash) {
qDebug(logDatabase()) << Q_FUNC_INFO << "hash";
    QList<QString> info;
    QSqlQuery query(db);
    if(!db.open()) {
        qCritical(logDatabase()) << "Database:" << db.lastError().text();
    }
    QString strKey = QString("SELECT name, mode, id_device, key FROM Accounts WHERE hash = :hash");
    query.prepare(strKey);
    query.bindValue(":hash", hash);
    if(query.exec()) {
        if(query.next()) {
            info.append(query.value("name").toString());
            info.append(query.value("mode").toString());
            info.append(query.value("id_device").toString());
            info.append(query.value("key").toString());
        }
        else {
qDebug(logDatabase()) << "Info is absent" << hash;
        }
    }
    else qCritical(logDatabase()) << "QSqlQuery error:" << query.lastError().text();
    return info;
}

QList<QString> Database::getOfOldFriend(QString id) {
qDebug(logDatabase()) << Q_FUNC_INFO << "id" << QThread::currentThreadId();
    QMutexLocker lMutex(&mutex);
    QList<QString> oldClient;
    QSqlQuery query(db);
    if(!db.open()) {
        qCritical(logDatabase()) << "Database:" << db.lastError().text();
    }
    QString strKey = QString("SELECT key, name, mode FROM Accounts WHERE id_device = :id_device");
    query.prepare(strKey);
    query.bindValue(":id_device", id);
    if(query.exec()) {
        if(query.next()) {
qDebug(logDatabase()) << "Device was verifyied";
            QString key = query.value("key").toString();
            QString name = query.value("name").toString();
            QString mode = query.value("mode").toString();
            oldClient << key << mode << name;
qDebug(logDatabase()) << "Information from databse:" << "oldClient";
        }
    }
    else {
        qCritical(logDatabase()) << "QSqlQuery error:" << query.lastError().text();
    }
    return oldClient;
}

bool Database::deleteEntry(QString id) {
qDebug(logDatabase()) << Q_FUNC_INFO << "id";
    QSqlQuery query(db);
    if(!db.open()) {
        qCritical(logDatabase()) << "Database:" << db.lastError().text();
    }
    QString strKey = QString("DELETE FROM Accounts WHERE id_device = :id_device");
    query.prepare(strKey);
    query.bindValue(":id_device", id);
    if(!query.exec()) {
        qCritical(logDatabase()) << "QSqlQuery error deleteDevice:" << query.lastError().text();
        return false;
    }
    return true;
}

bool Database::renameDeviceName(QString id, QString nickname) {
qDebug(logDatabase()) << Q_FUNC_INFO << "id << nickname";
    QSqlQuery query(db);
    if(!db.open()) {
        qCritical(logDeviceService()) << "Database:" << db.lastError().text();
    }
    QString strKey = QString("UPDATE Accounts SET name = :name WHERE id_device = :id_device");
    query.prepare(strKey);
    query.bindValue(":name", nickname);
    query.bindValue(":id_device", id);
    if(!query.exec()) {
        qCritical(logDatabase()) << "QSqlQuery error deleteDevice:" << query.lastError().text();
        return false;
    }
    return true;
}

bool Database::registryClient(QList<QString> infoClient) {
qDebug(logDatabase()) << Q_FUNC_INFO;
    QSqlQuery query(db);
    if(!db.open()) {
        qCritical(logDatabase()) << "Database:" << db.lastError().text();
        return false;
    }
    QString name = infoClient.at(1);  //ip, alianName, alianPubKey, alianId, localPass, alianPass
    QString publicKeyAlian = infoClient.at(2);
    QString id = infoClient.at(3);

    QCryptographicHash md5(QCryptographicHash::Md5);
    md5.addData(id.toUtf8());
    QString mdHex = md5.result().toHex();

    QString mode = name.right(1);
    name.chop(1);
//qDebug(logDatabase()) << id << mdHex << publicKeyAlian.size() << name << mode;
    QString str = QString("INSERT INTO Accounts(id_device, hash, key, name, mode) VALUES(:id, :hash, :key, :name, :mode);");
    query.prepare(str);
    query.bindValue(":id", id);
    query.bindValue(":hash", mdHex);
    query.bindValue(":key", publicKeyAlian);
    query.bindValue(":name", name);
    query.bindValue(":mode", mode);
    if(!query.exec()) {
        qCritical(logDatabase()) << "QSqlQuery error registry:" << query.lastError().text();
        return false;
    }
    return true;
}























