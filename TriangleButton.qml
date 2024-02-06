import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property int size: 100
    property color colorButton: "black"
    property bool mode: true
    property bool valid: true

    width: size + 25
    height: size + 25

    signal iconPressedOpened()
    signal iconPressedClosed()
    signal triedPress()

    function imitClick() {
        animateClose.start()
        iconPressedClosed()
        mode = !mode
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.width/2
        color: mouseArea.containsPress ? "#15DCDCDC" : "transparent"
    }

    Rectangle {
        id: field
        color: mouseArea.containsMouse ? Qt.darker(colorButton, 1.1) : colorButton
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.width / 5
        width: size
        height: size
        visible: false
    }
    Image {
        id: mask
        source: "qrc:/icons/icons/triangleButton.png"
        smooth: true
        visible: false
    }
    OpacityMask {
        anchors.fill: field
        source: field
        maskSource: mask
    }
    Rectangle {
        id: tail
        height: 0
        width: 3
        color: colorButton
        anchors.bottom: field.verticalCenter
        anchors.horizontalCenter: field.horizontalCenter
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: parent.enabled
        onClicked: {
            if(valid) {
                if(mode) {
                    animateOpen.start()
                    iconPressedOpened()
                }
                else {
                    animateClose.start()
                    iconPressedClosed()
                }
                mode = !mode
            }
            else {
                triedPress()
            }
        }
    }

    SequentialAnimation {
        id: animateOpen

        NumberAnimation {
            target: root
            from: field.rotation
            to: field.rotation + 90
            property: "rotation"
            duration: 200
        }
        NumberAnimation {
            target: tail
            from: 0
            to: 17
            property: "height"
            duration: 100

        }
    }
    SequentialAnimation {
        id: animateClose

        NumberAnimation {
            target: tail
            from: 17
            to: 0
            property: "height"
            duration: 100
        }
        NumberAnimation {
            target: root
            from: field.rotation + 90
            to: field.rotation
            property: "rotation"
            duration: 200
        }
    }
}
