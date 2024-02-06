import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property int size: 30
    property color colorImage: "black"
    property alias imageSource: image.source
    property bool mode: false
    property alias notifStatus: notifStatus.visible

    function runNotification() {
        mode = !mode
        animate.start()
        if(mode) notificationOpened()
        else notificationClosed()
    }

    signal notificationOpened()
    signal notificationClosed()

    width: size + 20
    height: size + 20

    Rectangle {
        anchors.fill: parent
        radius: parent.width/2
        color: mouseArea.containsPress ? "#15DCDCDC" : "transparent"
    }

    Rectangle {
        id: notifStatus
        z:1
        height: 12
        width: height
        radius: height / 2
        color: "red"
        anchors.left: field.horizontalCenter
        anchors.leftMargin: 3
        anchors.bottom: field.verticalCenter
        anchors.bottomMargin: 3
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: runNotification()
    }

    Rectangle {
        id: field
        anchors.centerIn: parent
        color: (mouseArea.containsMouse && root.enabled) ? Qt.darker(colorImage, 1.2) : colorImage
        width: mouseArea.containsPress ? size + 2 : size
        height: mouseArea.containsPress ? size + 2 : size
        visible: false
    }
    Image {
        id: image
        smooth: true
        visible: false
    }
    OpacityMask {
        anchors.fill: field
        source: field
        maskSource: image
    }
    SequentialAnimation {
        id: animate
        onStarted: mouseArea.enabled = false
        onFinished: {
            if(mode) imageSource = "qrc:/icons/icons/notificationOpened.png"
            else imageSource = "qrc:/icons/icons/notificationClosed.png"
            mouseArea.enabled = true
        }

        NumberAnimation {
            target: root
            property: "rotation"
            from: root.rotation
            to: root.rotation + 35
        }
        NumberAnimation {
            target: root
            property: "rotation"
            from: root.rotation + 35
            to: root.rotation - 70
            duration: 150
        }
        NumberAnimation {
            target: root
            property: "rotation"
            from: root.rotation - 90
            to: root.rotation
            duration: 150
        }
    }
}
