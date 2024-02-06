import QtQuick 2.0

Rectangle {
    id: root

// public
    property bool checked: false

    signal clicked(bool checked);  // onClicked:{root.checked = checked;  print('onClicked', checked)}

// private
    width: 80;  height: 23 // default size
    border.width: 0.05 * root.height
    border.color: "white"
    radius:       0.5  * root.height
    color:        checked? '#d4d4d4': '#5c4978' // background
    opacity:      enabled  &&  !mouseArea.pressed? 1: 0.3 // disabled/pressed state

    Text {
        text:  checked?    'On': 'Off'
        color: checked? '#443659': 'white'
        x:    (checked? 0: pill.width) + (parent.width - pill.width - width) / 2
        font.pixelSize: 0.6 * root.height
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle { // pill
        id: pill

        x: checked? root.width - pill.width: 0 // binding must not be broken with imperative x = ...
        width: root.height;  height: width // square
        border.width: parent.border.width
        radius:       parent.radius
        color: '#d4d4d4'
        border.color: '#5c4978'
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        drag {
            target:   pill
            axis:     Drag.XAxis
            maximumX: root.width - pill.width
            minimumX: 0
        }

        onReleased: { // releasing at the end of drag
            if( checked  &&  pill.x < root.width - pill.width)  root.clicked(false) // right to left
            if(!checked  &&  pill.x)                            root.clicked(true ) // left  to right
        }

        onClicked: root.clicked(!checked) // emit
    }
}
