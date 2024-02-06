import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property alias backgroundColor: backgroundMenu.color
    property color backgroundBorderColor: "transparent"
    property color colorText: "white"
    property color colorIcon: "white"

    property int sizeElement: 42

    signal openSettings()
    signal openReport()
    signal openAddDevice()


    Rectangle {
        id: backgroundMenu
        anchors.fill: parent
        radius: 25
        border.width: 3
        border.color: backgroundBorderColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 10
        spacing: 10

        ItemMenuSettings {
            id: report
            height: sizeElement
            colorTextLabel: colorText
            colorIconField: colorIcon
            textLabel: qsTr("Отчёт")
            imageSource: "qrc:/icons/icons/report.png"
            onClickedMenuItem: openReport()
        }

        ItemMenuSettings {
            id: settings
            height: sizeElement
            colorTextLabel: colorText
            colorIconField: colorIcon
            textLabel: qsTr("Настройки")
            imageSource: "qrc:/icons/icons/settings.png"
            onClickedMenuItem: openSettings()
        }

        ItemMenuSettings {
            id: addDevice
            height: sizeElement
            colorTextLabel: colorText
            colorIconField: colorIcon
            textLabel: qsTr("Добавить")
            imageSource: "qrc:/icons/icons/add.png"
            onClickedMenuItem: openAddDevice()
        }
    }
}
