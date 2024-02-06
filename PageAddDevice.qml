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
    property color colorWindows: "#25bdbdbd"
    property color colorHeaders: "#80bdbdbd"
    property int radiusItems: 10
    property color imageColorCopy: "#d7d7d7"
    property alias textId: textId.text
    property bool stateSwitch: false
    property color iconAddDeviceIdColor: "white"
    property int sizeIconAddId: 160
    visible: false

    signal addDevice(string code);

    CustomPopup {
        id: popup
        colorPopup: Qt.darker(colorHeaders, 0.5)
    }

    function responseAddDevice(response) {
console.log("responseAddDevice is " + response);
        switch(response) {
        case 0:
            popup.textPopup = qsTr("Пользователь успешно добавлен")
            popup.error = false
            break
        case 1:
            popup.textPopup = qsTr("Нельзя добавлять самого себя")
            popup.error = true
            break
        case 2:
            popup.textPopup = qsTr("Данный пользователь уже добавлен")
            popup.error = true
            break
        case 3:
            popup.textPopup = qsTr("Данный пользователь не обнаружен")
            popup.error = true
            break
        case 4:
            popup.textPopup = qsTr("Неверный код")
            popup.error = true
            break
        default:
console.log("error responseAddDevice")
            break
        }
        popup.open()
    }

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

    RowLayout {
       anchors.fill: parent
       anchors.margins: 35

       Rectangle {
           id: id
           color: colorWindows
           height: parent.height
           width: parent.width / 2.2
           Layout.alignment: Qt.AlignHCenter
           radius: radiusItems

           Rectangle {
               id: headerId
               width: parent.width
               height: radiusItems*4
               anchors.top: parent.top
               radius: radiusItems
               color: colorHeaders
               Label {
                   id: topicId
                   anchors.centerIn: parent
                   text: qsTr("Id устройства")
                   font.bold: true
                   color: "white"
                   font.pixelSize: 16
               }
               Rectangle {
                   id: fieldId
                   color: "white"
                   visible: false
                   anchors.top: topicId.bottom
                   anchors.topMargin: 20
                   anchors.horizontalCenter: parent.horizontalCenter
                   width: parent.width - 2 * 60
                   height: width
               }
               Image {
                   id: imageId
                   smooth: true
                   source: "qrc:/icons/icons/qrFrame.png"
                   visible: false
               }
               OpacityMask {
                   anchors.fill: fieldId
                   source: fieldId
                   maskSource: imageId
               }
           }
           Label {
               id: textId
               font.bold: true
               color: mouseAreaCopy.containsMouse ? Qt.darker("white", 1.2) : "white"
               font.pixelSize: 16
               anchors.bottom: parent.bottom
               anchors.bottomMargin: 30
               anchors.left: parent.left
               anchors.leftMargin: 30
           }
           Image {
               id: iconCopy
               smooth: true
               visible: false
           }
           Rectangle {
               id: fieldIconCopy
               color: imageColorCopy
               anchors.right: parent.right
               anchors.rightMargin: 30
               anchors.verticalCenter: textId.verticalCenter
               height: textId.height
               width: height
               visible: false
           }
           OpacityMask {
               id: maskIconCopy
               anchors.fill: fieldIconCopy
               source: fieldIconCopy
               maskSource: iconCopy
               opacity: 0
           }

           NumberAnimation {
               target: maskIconCopy
               property: "opacity"
               duration: 100
               from: mouseAreaCopy.containsMouse ? 0 : 1
               to: mouseAreaCopy.containsMouse ? 1 : 0
               running: mouseAreaCopy.containsMouse || !mouseAreaCopy.containsMouse
           }
           MouseArea {
               id: mouseAreaCopy
               anchors.left: parent.left
               anchors.leftMargin: 15
               anchors.right: parent.right
               anchors.rightMargin: 15
               anchors.verticalCenter: textId.verticalCenter
               height: textId.height + 10
               hoverEnabled: true
               onClicked: {
                   iconCopy.source = "qrc:/icons/icons/markCheckCopy.png"
                   guiService.copyId(textId.text);
               }
               onContainsMouseChanged: {
                   if(guiService.getStateCopied()) {
                        iconCopy.source = "qrc:/icons/icons/markCheckCopy.png"
                   }
                   else {
                       iconCopy.source = "qrc:/icons/icons/copyId.png"
                   }
               }
           }
       }

       Rectangle {
           id: add
           color: colorWindows
           height: parent.height
           width: parent.width / 2.2
           Layout.alignment: Qt.AlignHCenter
           radius: radiusItems
           Rectangle {
               id: headerAdd
               width: parent.width
               height: radiusItems*4
               anchors.top: parent.top
               radius: radiusItems
               color: colorHeaders
               Label {
                   anchors.centerIn: parent
                   text: qsTr("Добавить устройство")
                   font.bold: true
                   color: "white"
                   font.pixelSize: 16
               }
           }
           Image {
               id: iconAddDeviceId
               source: "qrc:/icons/icons/addDeviceId.png"
               smooth: true
               visible: false
           }
           MouseArea {
               id: mouseAreaAddDeviceId
               anchors.fill: fieldAddDeviceId
               hoverEnabled: true
               onClicked: {
                   if(addId.length == 20) {
                       if(stateSwitch) {
                           stateSwitch = false
                           animateLabelProxy.running = true
                           addDevice(addId.text + "1")
                       }
                       else {
                           stateSwitch = false
                           addDevice(addId.text + "0")
                       }
                       addId.text = ""
                       addId.focus = false
                   }
               }
           }
           Rectangle {
               id: fieldAddDeviceId
               color: mouseAreaAddDeviceId.containsMouse ? Qt.darker(iconAddDeviceIdColor, 1.2) : iconAddDeviceIdColor
               width: mouseAreaAddDeviceId.containsPress ? sizeIconAddId + 20 : sizeIconAddId
               height: width
               anchors.centerIn: parent
               visible: false
           }
           OpacityMask {
               anchors.fill: fieldAddDeviceId
               source: fieldAddDeviceId
               maskSource: iconAddDeviceId
           }

           Label {
               id: labelProxy
               text: qsTr("Доверенный режим включён")
               anchors.bottom: addId.top
               anchors.bottomMargin: 18
               anchors.left: addId.left
               opacity: 0
               color: "red"
               font.italic: true
               font.pixelSize: 14

               NumberAnimation {
                   id: animateLabelProxy
                   target: labelProxy
                   property: "opacity"
                   duration: 150
                   from: stateSwitch ? 0 : 1
                   to: stateSwitch ? 1 : 0
               }
           }

           TextInput {
               id: addId
               maximumLength: 20
               font.bold: true
               font.pixelSize: 16
               color: "white"
               cursorVisible: false
               anchors.bottom: parent.bottom
               anchors.bottomMargin: 30
               anchors.right: parent.right
               anchors.rightMargin: 30
               anchors.left: parent.left
               anchors.leftMargin: 30

               Rectangle {
                   anchors.centerIn: parent
                   width: parent.width + 2 * 10
                   height: parent.height + 2 * 10
                   border.color: "white"
                   border.width: 1
                   radius: 25
                   color: "transparent"
               }
               MouseArea {
                   id: mouseAreaAddId
                   anchors.centerIn: parent
                   width: parent.width + 2 * 20
                   height: parent.height + 2 * 20
                   hoverEnabled: true
                   onClicked: {
                       addId.forceActiveFocus()
                   }
               }
               Keys.onPressed: (event) => {
                   if(event.key === 16777220) {
                       addId.focus = false
                   }
               }
           }
           CustomSwitch {
               id: customSwitch
               anchors.verticalCenter: addId.verticalCenter
               anchors.right: addId.right
               anchors.rightMargin: 10
               opacity: 0
               checked: stateSwitch
               onClicked: (checked) => {
                   stateSwitch = checked
                   animateLabelProxy.running = true
               }
               NumberAnimation {
                   id: animateCustomSwitch
                   target: customSwitch
                   property: "opacity"
                   duration: 100
                   from: mouseAreaAddId.containsMouse ? 0 : 1
                   to: mouseAreaAddId.containsMouse ? 1 : 0
                   running: mouseAreaAddId.containsMouse || !mouseAreaAddId.containsMouse
               }
           }
       }
    }

    NumberAnimation {
        id: animate
        target: root
        property: "opacity"
        duration: 300
        onStarted: {
            root.visible = true
        }
        onFinished: {
            if(!root.opacity) {
                stateSwitch = false
                addId.text = ""
                root.visible = false
                addId.focus = false
            }
        }
    }
}
