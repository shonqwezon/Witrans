#ifndef CONFIG_H
#define CONFIG_H
#include <QByteArray>
#include <QDir>

namespace DataBase {
    const QString dbName = "data.dll";
}

namespace Port {
    const quint16 broadcast = 14488;
    const quint16 tcp = 8467;
};

enum ActionType {
    TYPE_CONTINUE,
    TYPE_PAUSE,
    TYPE_STOP
};

enum PacketType {
    TYPE_MSG,
    TYPE_REQUEST_FILE,
    TYPE_ACCEPT_FILE,
    TYPE_STOP_FILE,
    TYPE_KEYADD,
    TYPE_OLDFRIEND,
    TYPE_DELETE,
    TYPE_REJECT_FILE,
    TYPE_CANCEL_REQUEST
};

enum ValueType {
    TYPE_SERVER,
    TYPE_CLIENT,
    TYPE_BASECODE,
    TYPE_NAME
};

enum HashType {
    TYPE_ALIAN_PASS,
    TYPE_LOCAL_PASS,
    TYPE_ID,
    TYPE_MODE,
    TYPE_USERNAME
};

enum RequestType {
    TYPE_NOERROR,
    TYPE_LOCALIP,
    TYPE_EXIST,
    TYPE_WRONGIP,
    TYPE_WRONGKEY,
    TYPE_SOMEERROR,
    TYPE_ACCEPT_COOKIES,
    TYPE_ERROR_COOKIES,
    TYPE_ERROR_STOP_FILE,
    TYPE_ERROR_EXISTS_FILE,
    TYPE_ERROR_OPEN_FILE,
    TYPE_ERROR_DECRYPT_FILE
};

namespace Status {
    const QByteArray ACCEPT_KEY = "12";
    const QByteArray ERROR_SIZE_KEY = "13";

    const QByteArray ACCEPT_PLAIN = "15";
    const QByteArray ERROR_PLAIN = "14";
    const QByteArray ERROR_SIZE_PLAIN = "16";

    const QByteArray ACCEPT_COOKIES = "23";
    const QByteArray ERROR_COOKIES = "24";

    const QByteArray FILE_READY = "87";
    const QByteArray ERROR_EXISTS_FILE = "64";
    const QByteArray ERROR_FILE = "17";
    const QByteArray FILE_STOP = "96";

    const QByteArray ERROR_SIZE_FILE = "18";
};

namespace RegistryGroups {
    namespace Settings {
        const QString avatar = "settings/avatar";
        const QString login = "settings/login";
        const QString minimized = "settings/minimized";
        const QString autopaste = "settings/autopaste";
    }
    namespace KeyBinds {
        const QString hideApp = "keybinds/hideApp";
    }
    namespace SavingPaths {
        const QString defaultPath = "savingpaths/defaultPath";
    }
}

namespace Config {
    const int sizeToken = 16;
    const qint64 fileSegmentSize = 1024 * 64;

    const QString cfgName = "config.ini";
    const qsizetype sizePublicKey = 800;
    const qsizetype sizeDeviceId = 20;
    const qint64 sizeAvatar = 1024 * 1024 * 0.5;
};

#endif // CONFIG_H
