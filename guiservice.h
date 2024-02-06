#ifndef GUISERVICE_H
#define GUISERVICE_H

#include <QObject>
#include <QDebug>
#include <QGuiApplication>
#include <QClipboard>
#include <QFileInfo>
#include <QHash>
#include "config.h"
#include <QKeySequence>
#include <QKeyEvent>
#include <QProcess>
#include <QFileInfo>
#include <windows.h>

#include "loggingcategories.h"

class GuiService : public QObject
{
    Q_OBJECT
public:
    explicit GuiService(QObject *parent = nullptr);
    ~GuiService();

    static QString convertSize(qint64 bytes);

signals:
    void activeDeleteButton();
    void deactiveDeleteButton();

    void activeActionButtons();
    void deactiveActionButtons();

public slots:
    void openFile(QString filePath);
    void openDirectory(QString filePath);

    void copyText(QString string);

    bool getStateCopied();
    void copyId(QString code);

    void clearDeviceCode();
    void changeDeviceCode(QString deviceCode);

    QString checkSizeAvatar(QString url);

    QList<QList<QString>> getCopiedData();
    QList<QList<QString>> appendFiles(QString paths);

    void clearFiles();
    void addDeleteFile(bool mode, QString path);
    void deleteSelectedFiles();

    void addChangeData(bool mode, int dataId);

    void renameFile(QString path, QString newName);

    QHash<QString, QString> getFiles();

    static QString getKeysSequence(int modifier, int key);

private:
    QString m_deviceCode = "";
    QHash<QString, QString> files; //path + name
    QList<QString> selectedDeleteFiles;
    QList<int> changeFiles;
};

#endif // GUISERVICE_H
