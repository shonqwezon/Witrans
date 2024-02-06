import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Page {
    id: root
    property alias colorPage: backColor.color
    property color colorDevice: "lightblue"
    property color colorTypeDevice: "black"
    property int sizeTypeDevice: 30

    signal deleteDevice(string ip)
    signal renameDevice(string ip, string name)
    signal addReceivers(string ip)
    signal deleteReceivers(string ip)
    signal clearReceivers()
    signal disconectedDevice(string ip)

    background: Rectangle {
        id: backColor
        radius: 25
        Rectangle {
            color: parent.color
            anchors.top: parent.top
            width: parent.width
            height: parent.radius
        }
        Rectangle {
            color: parent.color
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.radius
            height: parent.radius
        }
    }
    visible: false

    function appendNewDevice(ip, list) {
        dataModel.append({"ip": ip, "nick": list[0], "mode": list[1]})
    }

    ListModel {
        id: dataModel
    }

    signal closeBoxes(int index, bool unlockMode)

    GridView {
            id: table
            anchors.fill: parent
            anchors.margins: 15
            cellHeight: 146
            cellWidth: cellHeight
            model: dataModel
            boundsBehavior: Flickable.StopAtBounds
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 100
                }
            }
            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 100
                }
            }


            delegate: Item {
                property bool mode: true
                property bool openedAnother: false
                property bool colorMode: true
                height: table.cellHeight
                width: table.cellWidth
                Connections {
                    target: root
                    function onCloseBoxes(index, unlockMode) {
                        if(model.index !== index) {
console.log("Close " + model.index)
                            if(!mode) {
                                mode = !mode //true
                                animate.running = true
                                nickname.focus = false
                            }
                            if(!colorMode) {
                                colorMode = true
                                deviceBox.color = colorDevice
                                deleteReceivers(model.ip)
                            }
                            openedAnother = unlockMode ? false : true
                        }
                        else {
                            openedAnother = false
                        }
                    }
                    function onClearReceivers() {
console.log(model.index)
                        if(!colorMode) {
                            colorMode = true
                            deviceBox.color = colorDevice
                        }
                    }

                    function onDisconectedDevice(ip) {
                        if(model.ip == ip) {
console.log("disconnected " + model.index)
                            dataModel.remove(model.index)
                        }
                    }
                }

                Rectangle {
                    id: deviceBox
                    anchors.fill: parent
                    anchors.margins: 10
                    color: colorDevice
                    radius: 10
                    border {
                        color: "black"
                        width: 1
                    }
                    Item {
                        id: anchor
                        anchors.top: parent.top
                        anchors.bottom: nickname.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: false
                    }

                    RoundAvatar {
                        id: avatar
                        anchors.centerIn: anchor
                        size: mouseAreaDevice.containsMouse ? 90 : 85
                        colorImage: "#852431"
                        sourceImage: "qrc:/icons/icons/defaultUser.png"

                        NumberAnimation {
                            id: animate
                            target: avatar
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 150
                            easing.type: Easing.InOutQuad
                            onFinished: {
                                if(mode) {
                                    avatar.icon = false
                                    avatar.sourceImage = "qrc:/icons/icons/defaultUser.png"
                                }
                                else {
                                    avatar.icon = true
                                    avatar.sourceImage = "qrc:/icons/icons/delete.png"
                                }

                                animateEnd.running = true
                            }
                        }
                        NumberAnimation {
                            id: animateEnd
                            target: avatar
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 150
                            easing.type: Easing.InOutQuad
                        }
                        MouseArea {
                            id: mouseAreaDevice
                            anchors.fill: parent
                            enabled: root.enabled
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onContainsMouseChanged: {
                                if(colorMode) {
                                    mouseAreaDevice.containsMouse ? deviceBox.color = Qt.darker(colorDevice, 1.1) : deviceBox.color = colorDevice
                                }
                            }

                            onClicked: (mouse) => {
                                if(mouse.button == Qt.LeftButton && mode && !openedAnother) {
                                    colorMode ? deviceBox.color = Qt.darker(colorDevice, 1.3) : deviceBox.color = Qt.darker(colorDevice, 1.1)
                                    colorMode ? addReceivers(model.ip) : deleteReceivers(model.ip)
                                    colorMode = !colorMode
                                }
                                if(mouse.button == Qt.LeftButton && !mode) {
console.log("delete " + model.index)
                                    closeBoxes(model.index, true);
                                    deleteDevice(model.ip)
                                }
                            }
                            onDoubleClicked: (mouse) => {
                                if(mouse.button == Qt.RightButton && colorMode) {
                                    mode = !mode //false
                                    nickname.focus = false
                                    closeBoxes(model.index, mode);
                                    animate.running = true
console.log(model.index)
                                }
                            }
                        }

                    }
                    TextInput {
                        property string name: ""
                        id: nickname
                        enabled: mode ? false : true
                        maximumLength: 10
                        text: model.nick
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        font.bold: true
                        font.pixelSize: 17
                        color: mode ? "#333333" : "#ba4f3c"
                        Keys.onPressed: {
                            if(event.key === 16777220) {
                                nickname.focus = false
                                mode = !mode //false
                                closeBoxes(model.index, mode);
                                animate.running = true
console.log(model.index)
                            }
                        }
                        onFocusChanged: {
console.log("focused")
                            if(nickname.focus) name = nickname.text
                            if(!nickname.focus && name != nickname.text) {
                                if(nickname.length > 3) renameDevice(model.ip, nickname.text)
                                else nickname.text = name
                            }
                        }
                    }
                    MouseArea {
                        id: mouseAreaNickname
                        anchors.fill: nickname
                        hoverEnabled: true
                        enabled: !mode
                        onClicked: nickname.forceActiveFocus()
                    }

                    Rectangle {
                        anchors.centerIn: nickname
                        height: nickname.height + 7
                        width: nickname.width + 16
                        color: mouseAreaNickname.containsMouse ? "#10000000" : "transparent"
                        border.width: 2
                        border.color: nickname.focus ? "#29b365" : "transparent"
                        radius: 10
                    }
                }
            }
        }
}
