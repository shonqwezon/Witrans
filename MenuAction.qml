import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Item {
    id: root
    height: heightIcon

    property alias icon: icon.source
    property alias iconColor: field.color
    property int widthIcon
    property int heightIcon
    property bool click: true

    signal pressedIcon()

    Image {
        id: icon
        smooth: true
        visible: false
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: parent.enabled
        onClicked: {
            if(click) {
                iconColor = Qt.darker(iconColor, 0.8)
                pressedIcon()
            }
        }

        onContainsMouseChanged: {
            if(click) {
                iconColor = containsMouse ? Qt.darker(iconColor, 1.25) : Qt.darker(iconColor, 0.8)
            }
        }
    }

    Rectangle {
        id: field
        width: (mouseArea.containsPress && click) ? widthIcon + 2 : widthIcon
        height: (mouseArea.containsPress && click) ? heightIcon + 2 : heightIcon
        anchors.centerIn: parent
        visible: false
    }

    OpacityMask {
        id: mask
        anchors.fill: field
        source: field
        maskSource: icon
    }
}
