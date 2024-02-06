import QtQuick 2.0
import QtQuick.Window 2.15
import QtQuick.Controls 2.15

Window {
    property string handle
    property string user
    property string type
    property string body

    id: root
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WA_ShowWithoutActivating | Qt.WA_TranslucentBackground
    color: "#00000000"
    visible: false
    height: 80
    width: 200

    function updatePosition() {
        animUpdatePosition.start()
    }

    NumberAnimation {
        id: animUpdatePosition
        target: root
        property: "y"
        duration: 400
        to: root.y + (root.height + 10)
        easing.type: Easing.InOutQuad
    }
    signal destroyNotif()

    signal acceptFiles(string handle, string type)
    signal acceptText(string handle, string text)
    signal rejectText(string handle)
    signal moreDetails(string handle)

    SequentialAnimation {
        id: animRoot
        running: true
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 1000
            easing.type: Easing.InOutQuad
            from: 0
            to: 1
        }
        PauseAnimation { duration: 58000 }
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 1000
            easing.type: Easing.InOutQuad
            from: 1
            to: 0
        }
        onStarted: {
            root.opacity = 0
            root.visible = true
        }
        onRunningChanged: {
            if(!running) destroyNotif()
        }
    }

    ParallelAnimation {
        id: animAccept
        NumberAnimation {
            target: root
            property: "x"
            duration: 500
            easing.type: Easing.InOutQuad
            to: root.x-root.width
        }
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 500
            easing.type: Easing.InOutQuad
            to: 0
        }
        ColorAnimation {
            target: background
            property: "color"
            to: "lightgreen"
            duration: 1000
        }
        onRunningChanged: {
            if(!running) {
                root.destroy()
            }
        }
    }
    ParallelAnimation {
        id: animReject
        NumberAnimation {
            target: root
            property: "x"
            duration: 500
            easing.type: Easing.InOutQuad
            to: root.x+root.width
        }
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 500
            easing.type: Easing.InOutQuad
            to: 0
        }
        ColorAnimation {
            target: background
            property: "color"
            to: "red"
            duration: 1000
        }
        onRunningChanged: {
            if(!running) {
                root.destroy()
            }
        }
    }
    ParallelAnimation {
        id: animMoreDetails
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 800
            easing.type: Easing.InOutQuad
            to: 0
        }
        ColorAnimation {
            target: background
            property: "color"
            to: "lightblue"
            duration: 500
        }
        onRunningChanged: {
            if(!running) {
                root.destroy()
            }
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#90000000"
        radius: 15
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onDoubleClicked: {
                if(!animAccept.running && !animReject.running && !animMoreDetails.running) {
console.log("more")
                    moreDetails(handle)
                    animMoreDetails.start()
                }
            }
            onMouseXChanged: {
                if(!animAccept.running && !animReject.running && !animMoreDetails.running) {
                    if(mouseX < parent.x) {
console.log("accept")
                        if(type == "text") acceptText(handle, body)
                        else acceptFiles(handle, type)
                        animAccept.start()
                    }
                    if(mouseX > parent.x + parent.width) {
console.log("reject")
                        if(type == "text") rejectText(handle)
                        animReject.start()
                    }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: background.radius
            spacing: 3
            Row {
                spacing: 3
                Label {
                    id: username
                    text: user
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }
                Label {
                    id: colon
                    text: ":"
                    font.pixelSize: 17
                    font.bold: true
                    color: Qt.darker("white", 1.4)
                }
            }
            TextInput {
                id: info
                text: body
                font.pixelSize: 16
                font.bold: false
                maximumLength: 20
                color: "#f5f5dc"
                readOnly: true
            }
        }
    }
}
