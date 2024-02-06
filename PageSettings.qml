import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

Page {
    id: root
    padding: 20

    property alias login: login.text
    property alias loginFocus: login.focus
    property string sourceAvatar: ""

    property alias sequenceHideApp: inputShortCut.text
    property alias pathDefault: savingPathDefaultBody.path

    property alias radiusBack: back.radius
    property color colorWindows: "#25bdbdbd"
    property color colorHeaders: "#80bdbdbd"
    property int radiusItems: 8

    property int padds: 15
    property string currentVersion: ""
    property bool valid: true

    property bool modeMinimized
    property bool modeAutopaste

    visible: false

    signal checkSizeAvatar(string url);
    function restoreValid() {
        if(inputShortCut.visible){
            valid = false
            shortCutBodyHideApp.validHideApp = false
        }
        if(login.length<4) {
            valid = false
        }
    }

    function setAvatar(url) {
        if(url !== "") sourceAvatar = url
        else {
console.log("file is large")
           popup.open()
        }
    }

    CustomPopup {
        id: popup
        colorPopup: Qt.darker(colorHeaders, 0.5)
        textPopup: qsTr("Размер файла не должен превышать 1 Мб")
    }

    background: Rectangle {
        id: back
        color: "#474389"
        Rectangle {
            color: parent.color
            height: parent.radius
            width: parent.radius
            anchors.top: parent.top
            anchors.left: parent.left
        }
        Rectangle {
            color: parent.color
            height: parent.radius
            width: parent.radius
            anchors.top: parent.top
            anchors.right: parent.right
        }
    }
    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFile
        folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        nameFilters: ["Image files (*.png *.jpg)"]
        onAccepted: {
            checkSizeAvatar(fileDialog.file)
        }
    }
    Row {
        anchors.fill: parent
        spacing: 20

        Column {
            width: parent.width * 3/12 - 40/3
            height: parent.height
            spacing: 20
            Item {
                id: avatar
                width: parent.width
                height: width
                Rectangle {
                    id: headerAvatar
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Аватар")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
                Item {
                    width: parent.width
                    anchors.top: headerAvatar.bottom
                    anchors.bottom: parent.bottom
                    RoundAvatar {
                        id: roundAvatar
                        size: parent.width - 30
                        sourceImage: sourceAvatar
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: mouseAreaAvatar
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: fileDialog.open()
                    }
                    RoundAvatar {
                        id: roundChangeAvatar
                        size: mouseAreaAvatar.containsPress ? roundAvatar.size - 20 : roundAvatar.size - 40
                        colorImage: "#80000000"
                        sourceImage: "qrc:/icons/icons/chooseAvatar.png"
                        anchors.centerIn: roundAvatar
                        icon: true
                        opacity: 0

                        NumberAnimation {
                            target: roundChangeAvatar
                            property: "opacity"
                            duration: 150
                            from: mouseAreaAvatar.containsMouse ? 0 : 1
                            to: mouseAreaAvatar.containsMouse ? 1 : 0
                            running: mouseAreaAvatar.containsMouse || !mouseAreaAvatar.containsMouse
                        }
                    }
                }
            }
            Item {
                id: binds
                width: parent.width
                height: parent.height - avatar.height - 20
                Rectangle {
                    id: headerBinds
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Горячие клавишы")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
                Item {
                    id: anchorShortCutBodyHideApp
                    anchors.top: headerBinds.bottom
                    anchors.topMargin: 10 + (labelShortCut.height  + padds / 2) / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle {
                    property bool validHideApp: true
                    id: shortCutBodyHideApp
                    anchors.centerIn: anchorShortCutBodyHideApp
                    width: areaShortCutBodyHideApp.containsPress ? parent.width - padds * 2 + 2 : parent.width - padds * 2
                    height: areaShortCutBodyHideApp.containsPress ? labelShortCut.height + padds / 2 + 2 : labelShortCut.height + padds / 2
                    radius: height / 3
                    color: areaShortCutBodyHideApp.containsMouse ? "#402c2842" : "transparent"
                    border.width: 1
                    border.color: validHideApp ? headerBinds.color : "red"
                    Label {
                        id: labelShortCut
                        text: qsTr("Быстрое открытие")
                        color: "white"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        anchors.centerIn: parent
                    }
                    TextInput {
                        property bool modif: false
                        id: inputShortCut
                        width: parent.width
                        anchors.centerIn: parent
                        font.pixelSize: 16
                        color: "white"
                        visible: false
                        horizontalAlignment: Text.AlignHCenter
                        readOnly: true
                        Keys.onPressed: (event) => {
                            if(inputShortCut.visible && (event.modifiers == Qt.AltModifier || event.modifiers == Qt.ShiftModifier || event.modifiers == Qt.ControlModifier)) {
                                var sequence = guiService.getKeysSequence(event.modifiers, event.key);
                                if(sequence != "") {
                                    areaShortCutBodyHideApp.modifEvent = event.modifiers;
                                    areaShortCutBodyHideApp.keyEvent = event.key;
                                    inputShortCut.text = sequence;
                                }
                                event.accepted = true;
                            }
                        }
                    }
                    MouseArea {
                        property string oldSequence: ""
                        property int modifEvent: 0
                        property int keyEvent: 0
                        id: areaShortCutBodyHideApp
                        anchors.fill: shortCutBodyHideApp
                        hoverEnabled: true
                        onClicked: {
                            labelShortCut.visible = !labelShortCut.visible
                            inputShortCut.visible = !inputShortCut.visible
                            inputShortCut.forceActiveFocus()
                            if(inputShortCut.visible) {
                                oldSequence = inputShortCut.text
                                valid = false
                            }
                            else {
                                shortCutBodyHideApp.validHideApp = true
                                if(oldSequence != inputShortCut.text) {
                                    registry.setKeyBind(modifEvent, keyEvent);
                                    windowsHooks.setNewSequence(modifEvent, keyEvent);
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width * 5/12 - 40/3
            height: parent.height
            spacing: 20

            Item {
                id: nickname
                width: parent.width
                height: parent.height / 6
                Rectangle {
                    id: headerNickname
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Имя")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
                TextInput {
                    id: login
                    text: "undefinded"
                    width: parent.width - padds * 2
                    maximumLength: 10
                    font.bold: true
                    font.pixelSize: 16
                    color: "white"
                    validator: RegularExpressionValidator { regularExpression: /^[A-Za-zА-Яа-я0-9]+$/ }
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    onTextChanged: {
                        if(login.length<4) valid = false
                    }
                    onAccepted: loginFocus = false
                }
                Label {
                    anchors.left: login.horizontalCenter
                    anchors.verticalCenter: login.bottom
                    text: "%1/10".arg(login.length)
                    color: login.length < 4 ? "red" : "lightgreen"
                    font.italic: true
                    font.pixelSize: 13
                }
            }
            Item {
                id: saving
                width: parent.width
                height: parent.height - nickname.height - 20
                Rectangle {
                    id: headerSaving
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Сохранение файлов")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
                Item {
                    id: anchorSavingPathDefault
                    anchors.top: headerSaving.bottom
                    anchors.topMargin: 10 + savingPathDefaultBody.heightBasic / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                InputSavingPath {
                    id: savingPathDefaultBody
                    anchors.centerIn: anchorSavingPathDefault
                    widthParent: parent.width
                    paddsParent: padds
                    borderColor: headerSaving.color
                    namePath: qsTr("Директория по умолчанию")
                    onSavePath: (path) => {registry.setDefaultPath(path)}
                }
            }
        }

        Column {
            width: parent.width * 4/12 - 40/3
            height: parent.height
            spacing: 20

            Item {
                id: updating
                width: parent.width
                height: nickname.height
                Rectangle {
                    id: headerUpdating
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Обновления")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
                Label {
                    id: labelVersion
                    text: qsTr("Текущая версия:  %1").arg(currentVersion)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - padds * 2
                    font.pixelSize: 16
                    color: "white"
                }
            }
            Item {
                id: appStyle
                width: parent.width
                height: parent.height - updating.height - other.height - 40
                Rectangle {
                    id: headerAppStyle
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Стили")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
            }
            Item {
                id: other
                width: parent.width
                height: binds.height
                Rectangle {
                    id: headerОther
                    width: parent.width
                    height: radiusItems*2.5
                    anchors.top: parent.top
                    radius: radiusItems
                    color: colorHeaders
                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Прочее")
                        font.bold: true
                        color: "white"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: colorWindows
                    radius: radiusItems
                }
                CustomParameterSwitch {
                    id: bodyMinimized
                    text: qsTr("Минимизировать при запуске")
                    mode: modeMinimized
                    anchors.top: headerОther.bottom
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - padds * 2
                    height: labelHeight + padds / 2
                    onChangedMode: modeMinimized = bodyMinimized.mode
                }
                CustomParameterSwitch {
                    id: bodyAutopaste
                    text: qsTr("Автодобавление материала")
                    mode: modeAutopaste
                    anchors.top: bodyMinimized.bottom
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - padds * 2
                    height: labelHeight + padds / 2
                    onChangedMode: modeAutopaste = bodyAutopaste.mode
                }
            }
        }
    }
}
