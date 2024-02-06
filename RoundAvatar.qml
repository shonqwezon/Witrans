import QtQuick 2.15
import QtQuick.Controls 2.12
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property int size: 100
    property alias sourceImage: image.source
    property alias colorImage: mask.color
    property bool icon: false

    width: size
    height: size

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: size/2
        visible: false
        color: colorImage
    }
    OpacityMask {
        anchors.fill: mask
        source: icon ? mask : image
        maskSource: icon ? image : mask
    }
    Image {
        id: image
        smooth: true
        visible: false
    }
}
