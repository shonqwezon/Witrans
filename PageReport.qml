import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Page {
    id: root

    property alias runAnimate: animate.running
    property alias fromAnimate: animate.from
    property alias toAnimate: animate.to
    property alias radiusBack: back.radius

    visible: false

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
    NumberAnimation {
        id: animate
        target: root
        property: "opacity"
        duration: 300
        onStarted: root.visible = true
        onFinished: {
            if(!root.opacity) root.visible = false
        }
    }
    Label {
        anchors.centerIn: parent
        text: qsTr("В разработке")
        font.bold: true
        font.pixelSize: 22
        color: "white"
    }
}
