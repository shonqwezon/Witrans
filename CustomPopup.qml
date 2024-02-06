import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

Popup {
    property alias colorPopup: background.color
    property alias textPopup: text.text
    property bool error: true

    id: popup
    x: parent.width / 2 - popup.width / 2
    y: parent.height * 0.85
    background: Rectangle {
        id: background
        anchors.fill: parent
        radius: height / 2
    }
    Text {
        id: text
        anchors.centerIn: parent
        color: error ? "#b33443" : "green"
        font.bold: true
        font.pixelSize: 16
    }
    width: 400
    height: 40
    modal: true
    focus: true
    opacity: 0
    closePolicy: Popup.NoAutoClose
    onAboutToShow: SequentialAnimation {
        running: true
        NumberAnimation {
            target: popup
            property: "opacity"
            duration: 300
            easing.type: Easing.InOutQuad
            from: 0
            to: 1
        }
        PauseAnimation {
            duration: 1500
        }
        NumberAnimation {
            target: popup
            property: "opacity"
            duration: 300
            easing.type: Easing.InOutQuad
            from: 1
            to: 0
        }
        onFinished: popup.close()
    }
}
