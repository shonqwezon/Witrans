import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Item {
    id: root
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter

    property color colorTextLabel: "black"
    property color colorIconField: "black"
    property alias imageSource: image.source
    property alias textLabel: label.text
    property int sizeLabel: 16

    signal clickedMenuItem()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: clickedMenuItem()
    }

    Rectangle {
        anchors.centerIn: parent
        height: parent.height
        width: parent.width - 20
        color: mouseArea.containsPress ? "#15DCDCDC" : "transparent"
        radius: 10
    }
    Label {
        id: label
        color: colorTextLabel
        anchors.centerIn: parent
        font.pixelSize: mouseArea.containsPress ? sizeLabel + 1 : sizeLabel
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
    }
    Rectangle {
        id: field
        color: mouseArea.containsMouse ? Qt.darker(colorIconField, 1.1) : colorIconField
        width: mouseArea.containsPress ? 35 : 30
        height: mouseArea.containsPress ? 35 : 30
        anchors.left: parent.left
        anchors.leftMargin: 30
        anchors.verticalCenter: parent.verticalCenter
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
}
