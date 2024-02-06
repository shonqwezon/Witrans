#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "registry.h"
#include "service.h"
#include "updater.h"
#include "guiservice.h"
#include "deviceservice.h"

#include "server.h"

#include "eventfilter.h"
#include "windowshooks.h"
#include <windows.h>

#include <QSystemSemaphore>
#include <QSharedMemory>

#include <QFile>
#include <QDir>
#include <QScopedPointer>
#include <QTextStream>
#include <QDateTime>
#include <QLoggingCategory>
#include "loggingcategories.h"


QScopedPointer<QFile> m_logFile;
void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg);

int main(int argc, char *argv[]) {
    QCoreApplication::setOrganizationName("Witrans, Inc.");
    QCoreApplication::setApplicationName("Witrans");

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    #ifndef QT_DEBUG
        m_logFile.reset(new QFile(QCoreApplication::applicationDirPath() + QDir::separator() + "logs.txt"));
        m_logFile.data()->open(QFile::Append | QFile::Text);
        qInstallMessageHandler(messageHandler);
    #endif

    QSystemSemaphore semaphore("<uniq id>", 1);
    semaphore.acquire();
    QSharedMemory sharedMemory("<uniq id 2>");
    bool isAppRunning;
    if(sharedMemory.attach()) {
        isAppRunning = true;
    } else {
        sharedMemory.create(1);
        isAppRunning = false;
    }
    semaphore.release();

    if(isAppRunning){
        MessageBox(NULL, L"The Witrans is already running!", L"Witrans.exe", MB_ICONWARNING);
        return -1;
    }

    QQmlApplicationEngine engine;

    Registry registry;
    Updater updater;
    GuiService guiService;
    DeviceService deviceService;

    Server server(deviceService);
    server.startServer();

    Service service(deviceService);
    QObject::connect(&app, &QGuiApplication::aboutToQuit, &service, &Service::closeSession);

    EventFilter eventFilter(service);
    app.installNativeEventFilter(&eventFilter);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.rootContext()->setContextProperty("registry", &registry);
    engine.rootContext()->setContextProperty("updater", &updater);
    engine.rootContext()->setContextProperty("service", &service);
    engine.rootContext()->setContextProperty("guiService", &guiService);
    engine.rootContext()->setContextProperty("deviceService", &deviceService);
    engine.rootContext()->setContextProperty("server", &server);
    engine.rootContext()->setContextProperty("windowsHooks", &WindowsHooks::instance());

    engine.load(url);
qDebug(logMain()) << "App started";

    HWND hwnd = ::FindWindow(0, L"Witrans");
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, GetWindowLongPtr(hwnd, GWL_EXSTYLE) | WS_EX_APPWINDOW);

    return app.exec();
}

void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    QTextStream out(m_logFile.data());
    out << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz ");
    switch (type) {
        case QtInfoMsg:     out << "INF "; break;
        case QtDebugMsg:    out << "DBG "; break;
        case QtWarningMsg:  out << "WRN "; break;
        case QtCriticalMsg: out << "CRT "; break;
        case QtFatalMsg:    out << "FTL "; break;
    }
    out << context.category << ": " << msg << "\n";
    out.flush();
}
