QT += \
    quick \
    core5compat \
    network \
    sql

CONFIG += c++17

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        cipher.cpp \
        client.cpp \
        database.cpp \
        deviceservice.cpp \
        eventfilter.cpp \
        guiservice.cpp \
        loggingcategories.cpp \
        main.cpp \
        registry.cpp \
        server.cpp \
        service.cpp \
        socketthread.cpp \
        updater.cpp \
        windowshooks.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    cipher.h \
    client.h \
    config.h \
    database.h \
    deviceservice.h \
    eventfilter.h \
    guiservice.h \
    loggingcategories.h \
    registry.h \
    server.h \
    service.h \
    socketthread.h \
    updater.h \
    windowshooks.h

INCLUDEPATH += C:\Qt\Tools\OpenSSL\Win_x64\include
LIBS += -llibcrypto -lIphlpapi
QMAKE_LIBDIR += C:\Qt\Tools\OpenSSL\Win_x64\lib

VERSION = 0.1.0.7
QMAKE_TARGET_COMPANY = Witrans Inc.
QMAKE_TARGET_PRODUCT = Witrans
QMAKE_TARGET_COPYRIGHT = Copyright © 2022 Witrans Inc.
RC_ICONS += "icons/app.ico"
