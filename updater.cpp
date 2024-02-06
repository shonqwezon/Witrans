#include "updater.h"

Updater::Updater(QString v, QObject* parent) : QObject(parent), version(v) {
qDebug(logUpdater()) << "Initializated" << version;

    manager = new QNetworkAccessManager();
    QObject::connect(manager, &QNetworkAccessManager::finished, this, [=](QNetworkReply *reply) {
        if(reply->error()) {
            some_error(reply->errorString());
            return;
        }
        QString response = reply->readAll();
        QString availableVersion = response.left(response.indexOf('\n'));
        response.remove(0, response.indexOf('\n')+1);
        response.replace('\n', '#');
qDebug(logUpdater()) << "Current version: " + version << "Available version: " + availableVersion << "Arguments: " + response;
        if(availableVersion != version) {
            qDebug(logUpdater()) << "Update run";
            const char* sys = QString("start " + QGuiApplication::applicationDirPath() + QDir::separator() + "updater.exe %1 %2 %3").arg(QGuiApplication::applicationDirPath() + "/", availableVersion, response).toLatin1().constData();
            system(sys);
            QGuiApplication::quit();
        }
    });
    checkUpdate();
}

Updater::~Updater() {
qDebug(logUpdater()) << "Destroyed";
}

void Updater::checkUpdate() {
qDebug(logUpdater()) << "Checked update";
    manager->get(QNetworkRequest(QUrl("https://raw.githubusercontent.com/shonqwezon/Witrans/main/version")));
}

QString Updater::getCurrentVersion() const { return version; }

void Updater::some_error(QString error) {
    QString msg = QString("Error: The application cannot be updated. %1\nYour version is %2. Install new version manually?").arg(error, version);
    int msgboxID = MessageBoxA(NULL, msg.toStdString().c_str(), "Witrans's updator", MB_ICONERROR | MB_OKCANCEL);
    switch(msgboxID) {
        case IDOK:
        system("start https://github.com/shonqwezon/Witrans");
        break;
    }
}


