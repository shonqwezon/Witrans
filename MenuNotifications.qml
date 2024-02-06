import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects


Item {
    id: root
    property alias backgroundColor: backgroundMenu.color
    property color backgroundBorderColor: "transparent"
    property int marginButton: 8
    property int borderWidth: 3

    signal changeStatus(bool mode)
    signal closeNotif()

    Rectangle {
        id: backgroundMenu
        anchors.fill: parent
        radius: 25
        border.width: borderWidth - 1
        border.color: backgroundBorderColor
    }

//    Component.onCompleted: {
//        for(let i = 0; i < 120; i++) {
//            addNotification(["error", "кабанчик", "20.11.2021"])
//        }
//    }

    function addNotification(notif) {
        dataModel.append([{type: notif[0], content: notif[1], date: notif[2]}]);
        if(!buttonClear.enabled) {
            animButton.from = 0
            animButton.to = 1
            animButton.start()
            buttonClear.enabled = true
            changeStatus(true)
        }
    }

    ListModel {
        id: dataModel
    }

    Row {
        z: 2
        id: header
        height: 30
        anchors.top: parent.top
        anchors.topMargin: borderWidth
        anchors.left: parent.left
        anchors.leftMargin: borderWidth
        anchors.right: parent.right
        anchors.rightMargin: borderWidth
        Item {
            height: parent.height
            width: parent.width / 10
            Label {
                anchors.centerIn: parent
                text: qsTr("ID")
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }
        }
        Rectangle {
            radius: width / 2
            width: 1
            height: parent.height - 10
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            height: parent.height
            width: parent.width / 10 * 2 - 1
            Label {
                anchors.centerIn: parent
                text: qsTr("Тип")
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }
        }
        Rectangle {
            radius: width / 2
            width: 1
            height: parent.height - 10
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            height: parent.height
            width: parent.width / 10 * 5 - 1
            Label {
                anchors.centerIn: parent
                text: qsTr("Содержание")
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }
        }
        Rectangle {
            radius: width / 2
            width: 1
            height: parent.height - 10
            anchors.verticalCenter: parent.verticalCenter
        }
        Item {
            height: parent.height
            width: parent.width / 10 * 2 - 1
            Label {
                anchors.centerIn: parent
                text: qsTr("Время")
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }
        }
    }

    Rectangle {
        z: 2
        id: headerBottom
        color: "white"
        height: 2
        radius: height / 2
        width: header.width - 20
        anchors.top: header.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: header.horizontalCenter
    }
    Rectangle {
        z: 1
        id: headerHidden
        width: header.width
        anchors.top: header.verticalCenter
        anchors.horizontalCenter: header.horizontalCenter
        anchors.bottom: tableView.top
        color: backgroundColor
    }

    ListView {
        z: 0
        id: tableView
        anchors.top: headerBottom.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: header.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 55
        width: header.width
        boundsBehavior: Flickable.StopAtBounds
        spacing: 3

        model: dataModel

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


        delegate: Rectangle {
            id: itemDelegate
            implicitHeight: 30
            implicitWidth: tableView.width
            color: Qt.darker(backgroundColor, 1.2)
            radius: implicitHeight / 2

            Row {
                anchors.fill: parent
                Item {
                    height: parent.height
                    width: parent.width / 10
                    Label {
                        anchors.centerIn: parent
                        text: model.index
                        font.pixelSize: 14
                        color: "white"
                    }
                }
                Rectangle {
                    radius: width / 2
                    width: 1
                    height: parent.height - 10
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    height: parent.height
                    width: parent.width / 10 * 2 - 1
                    Label {
                        anchors.centerIn: parent
                        text: model.type
                        font.pixelSize: 14
                        color: "white"
                    }
                }
                Rectangle {
                    radius: width / 2
                    width: 1
                    height: parent.height - 10
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    height: parent.height
                    width: parent.width / 10 * 5 - 1
                    TextInput {
                        anchors.centerIn: parent
                        text: model.content
                        font.pixelSize: 14
                        color: "white"
                        maximumLength: 30
                        readOnly: true
                    }
                }
                Rectangle {
                    radius: width / 2
                    width: 1
                    height: parent.height - 10
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    height: parent.height
                    width: parent.width / 10 * 2 - 1
                    Label {
                        anchors.centerIn: parent
                        text: model.date
                        font.pixelSize: 14
                        color: "white"
                    }
                }
            }
        }
    }

    Item {
        id: anchorButton
        anchors.bottom: parent.bottom
        anchors.bottomMargin: borderWidth + backgroundMenu.radius
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Rectangle {
        id: buttonClear
        z: 1
        height: buttonMouseArea.containsPress ? backgroundMenu.radius + 15 : backgroundMenu.radius + 10
        radius: height
        width: buttonMouseArea.containsPress ? parent.width / 3 * 2 + 5 : parent.width / 3 * 2
        anchors.centerIn: anchorButton
        color: buttonMouseArea.containsMouse ? Qt.darker("#999999", 1.1) : "#999999"
        opacity: 0
        enabled: false
        Label {
            anchors.centerIn: parent
            text: qsTr("Очистить")
            color: "#b00000"
            font.pixelSize: 16
            font.bold: true
        }
        MouseArea {
            property bool mode: false
            id: buttonMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
console.log("clear notifications");
                animButton.from = 1
                animButton.to = 0
                animButton.start()
                buttonClear.enabled = false
                dataModel.clear()
                changeStatus(false)
                closeNotif()
            }
        }

        NumberAnimation {
            id: animButton
            target: buttonClear
            property: "opacity"
            duration: 200
        }
    }
}
