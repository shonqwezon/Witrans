import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts 1.12

Rectangle {
    id: root
    property alias label: btnLabel.text
    property color colorBackground
    signal clickedButton()

    color: mouseArea.containsMouse ? Qt.darker(colorBackground, 0.8) : colorBackground

    Label {
        id: btnLabel
        anchors.centerIn: parent
        font.pixelSize: mouseArea.containsPress ? 17 : 16
        font.bold: true
        color: "white"
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
    console.log("clicked")
            clickedButton()
        }
    }
}
