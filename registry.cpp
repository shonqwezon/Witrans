#include "registry.h"

Registry::Registry(QObject *parent) : QObject(parent) {
    if(!QFileInfo::exists(appPath + Config::cfgName)) {
        qDebug(logRegistry()) << "Add to autorun";
        QSettings settings("HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run", QSettings::NativeFormat);
        settings.setValue(QGuiApplication::applicationName(), QDir::toNativeSeparators(QCoreApplication::applicationFilePath()));
        settings.sync();
    }

    registry = new QSettings(appPath + Config::cfgName, QSettings::IniFormat);

    loginDefault = qgetenv("USERNAME");
    loginDefault = loginDefault.left(loginDefault.indexOf(" "));
    if(loginDefault.length()>10) loginDefault.resize(10);

    m_pathAvatar = registry->value(RegistryGroups::Settings::avatar, pathAvatarDefault).toString();
}

Registry::~Registry() {

}

void Registry::setLogin(const QString& login) {
    registry->setValue(RegistryGroups::Settings::login, login);
    registry->sync();
    emit changedLogin();
qDebug(logRegistry()) << "Set new login";
}

QString Registry::getLogin() const {
    return registry->value(RegistryGroups::Settings::login, loginDefault).toString();
}

void Registry::setAvatar(QString pathAvatar) {
    if(pathAvatar != ("file:///" + m_pathAvatar) && pathAvatar != pathAvatarDefault) {
        if(getAvatar() != pathAvatarDefault) QFile::remove(m_pathAvatar.remove("file:///"));
        pathAvatar.remove("file:///");
        QFileInfo fileInfo(pathAvatar);
        QString newFilePath = appPath+fileInfo.fileName();
        QFile::copy(fileInfo.filePath(), newFilePath);
        m_pathAvatar = newFilePath;

        emit changedAvatar();
        registry->setValue(RegistryGroups::Settings::avatar, m_pathAvatar);
        registry->sync();
qDebug(logRegistry()) << "Set new avatar";
    }
}

QString Registry::getAvatar() const {
    return (QFile(m_pathAvatar).exists() ? ("file:///" + m_pathAvatar) : pathAvatarDefault);
}

void Registry::setKeyBind(int modifier, int key) {
    registry->setValue(RegistryGroups::KeyBinds::hideApp, QString::number(modifier) + " " + QString::number(key));
    registry->sync();
qDebug(logRegistry()) << "Set new key bind";
}

QString Registry::getKeyBind() const {
    QString keyBind = registry->value(RegistryGroups::KeyBinds::hideApp, "134217728 87").toString();
    QString keySequence = GuiService::getKeysSequence(keyBind.left(keyBind.indexOf(" ") + 1).toInt(), keyBind.right(keyBind.length() - keyBind.indexOf(" ")).toInt());
    return keySequence;
}

void Registry::setMinimized(bool minimized) {
    registry->setValue(RegistryGroups::Settings::minimized, minimized);
    registry->sync();
qDebug(logRegistry()) << "Set new value minimized";
}

bool Registry::getMinimized() const {
    return registry->value(RegistryGroups::Settings::minimized, false).toBool();
}

void Registry::setAutopaste(bool autopaste) {
    registry->setValue(RegistryGroups::Settings::autopaste, autopaste);
    registry->sync();
qDebug(logRegistry()) << "Set new value autopaste";
}

bool Registry::getAutopaste() const {
    return registry->value(RegistryGroups::Settings::autopaste, true).toBool();
}

void Registry::setDefaultPath(QString path) {
    registry->setValue(RegistryGroups::SavingPaths::defaultPath, path + QDir::separator());
    registry->sync();
}

QString Registry::getDefaultPath() const {
    return registry->value(RegistryGroups::SavingPaths::defaultPath, QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).toString();
}

QString Registry::getName() {
    QString name = qgetenv("USERNAME");
    name = name.left(name.indexOf(" "));
    if(name.length()>10) name.resize(10);

    QSettings nameRegedit(QCoreApplication::applicationDirPath()+QDir::separator() + Config::cfgName, QSettings::IniFormat);
    return nameRegedit.value(RegistryGroups::Settings::login, name).toString();
}

QMultiHash<QString, unsigned long> Registry::getSequences() {
    QSettings sequences(QCoreApplication::applicationDirPath()+QDir::separator() + Config::cfgName, QSettings::IniFormat);
    QString hideApp = sequences.value(RegistryGroups::KeyBinds::hideApp, "134217728 87").toString();
    QMultiHash<QString, unsigned long> binds;
    binds.insert("hideApp", hideApp.right(hideApp.length() - hideApp.indexOf(" ")).toInt());
    binds.insert("hideApp", hideApp.left(hideApp.indexOf(" ") + 1).toInt());
    return binds;
}

QString Registry::getDownloadPath() {
    QSettings downloadPaths(QCoreApplication::applicationDirPath()+QDir::separator() + Config::cfgName, QSettings::IniFormat);
    return downloadPaths.value(RegistryGroups::SavingPaths::defaultPath, QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).toString();
}

QByteArray Registry::getDeviceId() {
    QSettings windowsID("HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion", QSettings::NativeFormat);
    return windowsID.value("ProductID", "undefinded").toString().remove('-').toUtf8();
}










