#include "guiservice.h"

GuiService::GuiService(QObject *parent) : QObject(parent) {

}

GuiService::~GuiService() {

}

void GuiService::copyText(QString string) {
    QGuiApplication::clipboard()->setText(string);
}

bool GuiService::getStateCopied() {
    QString currentText = QGuiApplication::clipboard()->text();
    if(currentText == m_deviceCode && !currentText.isEmpty()) return true;
    else return false;
}

void GuiService::copyId(QString deviceCode) {
    QGuiApplication::clipboard()->setText(deviceCode);
    changeDeviceCode(deviceCode);
}

void GuiService::clearDeviceCode() {
    m_deviceCode.clear();
}

void GuiService::changeDeviceCode(QString deviceCode) {
    m_deviceCode = deviceCode;
}

QString GuiService::checkSizeAvatar(QString url) {
    url.remove("file:///");
    qint64 size = QFileInfo(url).size();
qDebug(logGuiService()) << "Avatar size ==" << size;
    if(size > Config::sizeAvatar) return "";
    else return url.prepend("file:///");
}

QList<QList<QString>> GuiService::getCopiedData() {
qDebug(logGuiService()) << Q_FUNC_INFO;
    QString copiedData = QGuiApplication::clipboard()->text();
    QList<QList<QString>> data;
    data.append(QList<QString>("none"));
    if(!copiedData.isEmpty()) {
        if(copiedData.startsWith("file:///")) {
            data.first() = QList<QString>("file");

            QStringList filesString;
qDebug(logGuiService()) << "Type file";
            filesString = copiedData.split('\n');
//qDebug() << filesString;
            for(QString file : filesString) {
                if(!file.isEmpty()) {
                    file.remove("file:///");
                    QFileInfo fileInfo(file);
                    if(fileInfo.size() != 0) {
//qDebug(logGuiService()) << fileInfo.baseName() << fileInfo.size();
                        if(!files.contains(fileInfo.absoluteFilePath())) {
                            files.insert(fileInfo.absoluteFilePath(), fileInfo.baseName());
                            QList<QString> unit;
                            unit << fileInfo.baseName() << fileInfo.absoluteFilePath() << convertSize(fileInfo.size()) << fileInfo.suffix();
                            data.append(unit);
                        }
                    }
                }
            }
            if(data.size() == 1) data.first() = QList<QString>("none");
        }
        else {
qDebug(logGuiService()) << "Type text";
            data.first() = QList<QString>("text");

            data.append(QList<QString>(copiedData));
        }
    }
qDebug(logGuiService()) << "Current size of files:" << files.size();
    return data;
}

QList<QList<QString>> GuiService::appendFiles(QString paths) {
qDebug(logGuiService()) << Q_FUNC_INFO;
    QList<QList<QString>> data;
    data.append(QList<QString>("none"));
    if(paths.startsWith("file:///")) {
        data.first() = QList<QString>("file");

        QStringList filesString;
qDebug(logGuiService()) << "Type file" << paths;
        filesString = paths.split(",");
        for(QString file : filesString) {
            if(!file.isEmpty()) {
                file.remove("file:///");
                QFileInfo fileInfo(file);
                if(fileInfo.size() != 0) {
//qDebug(logGuiService()) << fileInfo.baseName() << fileInfo.size();
                    if(!files.contains(fileInfo.absoluteFilePath())) {
                        files.insert(fileInfo.absoluteFilePath(), fileInfo.baseName());
                        QList<QString> unit;
                        unit << fileInfo.baseName() << fileInfo.absoluteFilePath() << convertSize(fileInfo.size()) << fileInfo.suffix();
                        data.append(unit);
                    }
                }
            }
        }
    }
qDebug(logGuiService()) << "Current size of files:" << files.size();
    return data;
}

void GuiService::clearFiles() {
    files.clear();
    if(!selectedDeleteFiles.isEmpty()) {
qDebug(logGuiService()) << "ClearDeleteFiles";
        selectedDeleteFiles.clear();
        emit deactiveDeleteButton();
    }
}

void GuiService::addDeleteFile(bool mode, QString path) {
    if(mode) { //delete
        selectedDeleteFiles.append(path);
        if(selectedDeleteFiles.count() == 1) {
qDebug(logGuiService()) << "ActiveDeleteButton";
            emit activeDeleteButton();
        }
    }
    else {
        selectedDeleteFiles.remove(selectedDeleteFiles.indexOf(path));
        if(selectedDeleteFiles.isEmpty()) {
qDebug(logGuiService()) << "DeactiveDeleteButton";
            emit deactiveDeleteButton();
        }
    }
}

void GuiService::deleteSelectedFiles() {
    for(QString path : selectedDeleteFiles) {
        files.remove(path);
    }
    selectedDeleteFiles.clear();
qDebug(logGuiService()) << "Current size of files:" << files.size();
}

void GuiService::addChangeData(bool mode, int dataId) {
qDebug(logGuiService()) << "Change data" << "mode << dataId";
    if(mode) { //delete
        changeFiles.remove(changeFiles.indexOf(dataId));
        if(changeFiles.isEmpty()) {
qDebug(logGuiService()) << "Delete action buttons";
            emit deactiveActionButtons();
        }
    }
    else {
        changeFiles.append(dataId);
        if(changeFiles.count() == 1) {
qDebug(logGuiService()) << "Active action buttons";
            emit activeActionButtons();
        }
    }
}

void GuiService::renameFile(QString path, QString newName) {
qDebug(logGuiService()) << "Path:" << path << "-- new name:" << newName;
    files.insert(path, newName);
}

QHash<QString, QString> GuiService::getFiles() {
qDebug(logGuiService()) << Q_FUNC_INFO;
    return files;
}

QString GuiService::getKeysSequence(int modifier, int key) {
    if(QKeySequence(key).toString(QKeySequence::NativeText).toUtf8().length() != 1) {
        return "";
    }
    else {
        return QKeySequence(modifier).toString(QKeySequence::NativeText) + QKeySequence(key).toString(QKeySequence::NativeText);
    }
}

QString GuiService::convertSize(qint64 bytes) {
    if(bytes >= 1024) {
        if(bytes >= qPow(1024, 2)) {
            if(bytes >= qPow(1024, 3)) return QString::number(qRound(bytes / qPow(1024, 3))) + " Гб";
            else return QString::number(qRound(bytes / qPow(1024, 2))) + " Мб";
        }
        else return QString::number(qRound(bytes / 1024.0)) + " Кб";
    }
    else {
        return QString::number(bytes) + " байт";
    }
}

void GuiService::openDirectory(QString filePath) {
    QFileInfo file(filePath);
    QProcess::startDetached("explorer", {"/select,", file.fileName()}, file.path());
}
void GuiService::openFile(QString filePath) {
    QFileInfo file(filePath);
    QString path = QString("start /D \"%1\" %2").arg(file.path(), file.fileName());
    system(path.toStdString().c_str());
}

























