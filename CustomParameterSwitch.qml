import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

Rectangle {
    id: root
    color: "transparent"
    radius: height / 3

    property alias text: label.text
    property bool mode
    property alias labelHeight: label.height

    signal changedMode()

    Label {
        id: label
        color: areaStatus.containsMouse ? Qt.darker("white", 1.1) : "white"
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        anchors.left: parent.left
    }
    Rectangle {
        id: status
        width: parent.width / 4
        height: 3
        radius: height / 2
        anchors.top: label.bottom
        anchors.topMargin: 2
        Component.onCompleted: {
            status.x = mode ? 0 : root.width - status.width
            status.color = mode ? "lightgreen" : "red"
        }
    }
    MouseArea {
        id: areaStatus
        anchors.fill: parent
        hoverEnabled: true
        onMouseXChanged: {
            if(!animStatus.running) {
                if(mouseX >= parent.width / 2 && containsPress && mode) {
                    mode = false
                    changedMode()
                    animStatus.start()
                }
                if(mouseX <= parent.width / 2 && containsPress && !mode) {
                    mode = true
                    changedMode()
                    animStatus.start()
                }
            }
        }
    }
    ParallelAnimation {
        id: animStatus
        NumberAnimation {
            target: status
            property: "x"
            duration: 500
            easing.type: Easing.InOutQuad
            to: mode ? 0 : root.width - status.width
        }
        PropertyAnimation {
            property: "color"
            target: status
            to: mode ? "lightgreen" : "red"
            duration: 500
        }
    }
}
