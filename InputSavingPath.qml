import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

Rectangle {
    property bool validPath: true
    property int paddsParent
    property int heightBasic: labelPath.height + paddsParent / 2
    property int widthParent
    property color borderColor
    property string namePath
    property string path
    signal savePath(string path)

    id: root
    width: areaPath.containsPress ? widthParent - paddsParent * 2 + 2 : widthParent - paddsParent * 2
    height: areaPath.containsPress ? labelPath.height + paddsParent / 2 + 2 : labelPath.height + paddsParent / 2
    radius: height / 3
    color: areaPath.containsMouse ? "#402c2842" : "transparent"
    border.width: 1
    border.color: validPath ? borderColor : "red"
    TextInput {
        id: labelPath
        color: "white"
        text: namePath //areaPath.containsMouse ? path : namePath
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        anchors.centerIn: parent
        maximumLength: 34
        readOnly: true
    }

    NumberAnimation {
        id: animate
        target: labelPath
        property: "opacity"
        to: 0.5
        duration: 140
        easing.type: Easing.InOutQuad
        onFinished: {
            if(labelPath.text == namePath) labelPath.text = path
            else labelPath.text = namePath
            animateEnd.start()
        }
    }
    NumberAnimation {
        id: animateEnd
        target: labelPath
        property: "opacity"
        to: 1
        duration: 140
        easing.type: Easing.InOutQuad
    }

    MouseArea {
        id: areaPath
        anchors.fill: root
        hoverEnabled: true
        onClicked: {
            folderDialog.open()
        }
        onContainsMouseChanged: {
            if(!animate.running) animate.start()
            else {
                if(!containsMouse) {
                    animate.stop()
                    animateEnd.stop()
                    labelPath.opacity = 1
                    labelPath.text = namePath
                }
            }
        }
    }
    FolderDialog {
        id: folderDialog
        folder: path
        onAccepted: {
            path = folderDialog.folder.toString().substring(8)
            savePath(path)
        }
    }
}
