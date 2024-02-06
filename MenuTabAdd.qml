import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

Page {
    id: root

    property alias colorPage: backColor.color
    property color colorFileBoxes: "#80ffcabd"
    property color colorTextBoxes: "#80ffcabd"//"#40d4d4d4"
    property color colorImage: "white"

    background: Rectangle {
        id: backColor
        radius: 25
        Rectangle {
            color: parent.color
            anchors.top: parent.top
            width: parent.width
            height: parent.radius
        }
        Rectangle {
            color: parent.color
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.radius
            height: parent.radius
        }
    }
    visible: false

    Keys.onPressed: (event)=> {
        if ((event.key == Qt.Key_V) && (event.modifiers & Qt.ControlModifier)) {
console.log("get copied files");
            getCopiedData()
            event.accepted = true;
        }
    }

    function setDataModel(list) {
        if(!dataModelFiles.count && textArea.text.trim() === "") {
            var type = list.shift();
            switch(type[0]) {
                case 'text':
console.log("text adding")
                    changedReadyState(true)
                    touchField.enabled = false
                    textArea.text = list[0]
                    if(!fieldText.visible) fieldText.visible = true
                    stackView.replace(fieldText)
                    break;
                case 'file':
console.log("file adding")
                    changedReadyState(true)
                    touchField.enabled = false
                    list.forEach(function(obj) {
console.log(obj)
                        dataModelFiles.append({"name": obj[0], "path": obj[1], "size": obj[2], "type": obj[3]});
                    });
                    if(!tableFiles.visible) tableFiles.visible = true
                    stackView.replace(tableFiles)
                    break;
                default:
console.log("none adding")
                    changedReadyState(false)
                    touchField.enabled = true
                    break;
            }
            root.forceActiveFocus()
        }
    }
    function appendFiles(list) {
        if(list.length != 0) {
            var type = list.shift();
            switch(type[0]) {
                case 'text':
console.log("extra text")
                    touchField.enabled = false
                    textArea.append(list[0])
                    if(!fieldText.visible) fieldText.visible = true
                    if(stackView.currentItem != fieldText) {
                        dataModelFiles.clear();
                        clearFiles();
                        stackView.replace(fieldText)
                    }
                    changedReadyState(true)
                    break;
                case 'file':
console.log("extra file " + dataModelFiles.count + " " + list.length)
                    if(list.length) {
                        touchField.enabled = false
                        list.forEach(function(obj) {
console.log("obj")
                            dataModelFiles.append({"name": obj[0], "path": obj[1], "size": obj[2], "type": obj[3]});
                        });
                        if(!tableFiles.visible) tableFiles.visible = true
                        if(stackView.currentItem != tableFiles) {
                            textArea.clear()
                            stackView.replace(tableFiles)
                        }
                        changedReadyState(true)
                    }
                    break;
                default:
console.log("extra none")
                    touchField.enabled = true
                    break;
            }
        }
    }

    signal clearFiles();
    signal addFiles(string paths)
    signal getCopiedData();
    signal addDeleteFile(bool selected, string path)
    signal changedReadyState(bool state)
    signal renameFile(string path, string newName)

    function clearDataModel() {
        dataModelFiles.clear();
        textArea.clear()
        clearFiles();
        if(stackView.currentItem != mainWindow) {
            stackView.replace(mainWindow)
        }
    }
    function deleteFiles() {
console.log("delete files")
        deleteSelectedFiles();
        if(dataModelFiles.count == 0) {
            if(stackView.currentItem != mainWindow) {
                touchField.enabled = true
                stackView.replace(mainWindow)
            }
            changedReadyState(false)
        }
    }
    function sendData() {
console.log("send data")
        switch(stackView.currentItem) {
        case fieldText:
            return ['1', textArea.text]
        case tableFiles:
            return ['2']
        default:
            return ['0']
        }
    }

    ListModel {
        id: dataModelFiles
    }

    StackView {
        id: stackView
        initialItem: Item {
            id: mainWindow
            Label {
                id: mainLabel
                font.pixelSize: 16
                anchors.centerIn: parent
                font.underline: true
                text: "Двойной клик ЛКМ — открыть проводник\nКомбинация CTRL+V — вставить текст/файл"
                color: "#0e688f"
            }
        }
        anchors.fill: parent
        replaceEnter:
            Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 1
                }
            }
        replaceExit:
            Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 1
                }
          }
        anchors.margins: 15
    }

    signal deleteSelectedFiles();

    GridView {
        visible: false
        id: tableFiles
        cellHeight: cellWidth //130
        cellWidth: 117 //195
        model: dataModelFiles
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 100
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 100
            }
        }


        delegate: Item {
            property bool selected: false
            height: tableFiles.cellHeight
            width: tableFiles.cellWidth

            Connections {
                target: root
                function onDeleteSelectedFiles() {
                    if(selected) dataModelFiles.remove(model.index)
                }
            }

            function getImage(type) {
                switch(type) {
                case 'pdf':
                    return "qrc:/icons/icons/pdf.png"
                case 'doc' || 'docx':
                    return "qrc:/icons/icons/doc.png"
                case 'txt':
                    return "qrc:/icons/icons/txt.png"
                default:
                    return "qrc:/icons/icons/unknownFile.png"
                }
            }

            property bool mode: false

            Timer {
                id: timer
                interval: 1000
                repeat: false
                onTriggered: {
                    animate.start()
                }
            }

            Rectangle {
                id: fileBox
                anchors.fill: parent
                anchors.margins: 10
                color: colorFileBoxes
                radius: 10
                border {
                    color: "white"
                    width: 1
                }

                MouseArea {
                    id: mouseAreaIcon
                    enabled: !fileName.focus
                    anchors.fill: fileBox
                    hoverEnabled: true
                    onContainsMouseChanged: {
                        if(!selected) {
                            if(mouseAreaIcon.containsMouse && !mode) {
                                //console.log("start 1")
                                timer.start()
                            }
                            if(!mouseAreaIcon.containsMouse && !mode) {
                                //console.log("start 2")
                                timer.stop()
                            }

                            if(!mouseAreaIcon.containsMouse && mode) {
                                //console.log("start 3")
                                animateEnd.start()
                            }
                        }
                    }
                    onClicked: {
                        if(!mode && !animate.running && !animateEnd.running) {
                            selected = !selected
console.log("clicked " + selected)
                            fileBox.color = (selected ? Qt.darker(colorFileBoxes, 1.4) : colorFileBoxes)
                            timer.stop()
                            addDeleteFile(selected, model.path)
                        }
                    }
                }

                NumberAnimation {
                    id: animate
                    targets: [icon, fileName]
                    property: "opacity"
                    from: !mode ? 1 : 0
                    to: !mode ? 0 : 1
                    duration: 200
                    easing.type: Easing.InOutQuad
                    onFinished: {
                        if(!mode) {
                            fileBox.color = Qt.darker(colorFileBoxes, 0.5)
                            animateEnd.start()
                        }
                        else {
                            mode = false
                        }
                    }
                }
                NumberAnimation {
                    id: animateEnd
                    targets: [typeFile, sizeFile, typeFilePrefix, sizeFilePrefix]
                    properties: "opacity"
                    from: mode ? 1 : 0
                    to: mode ? 0 : 1
                    duration: 200
                    easing.type: Easing.InOutQuad
                    onFinished: {
                        if(mode) {
                            fileBox.color = colorFileBoxes
                            animate.start()
                        }
                        else {
                            mode = true
                        }
                    }
                }
                Label {
                    id: typeFilePrefix
                    text: "Тип: "
                    font.bold: true
                    font.pixelSize: 14
                    color: "black"
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    opacity: 0
                }
                Label {
                    id: typeFile
                    text: model.type
                    font.bold: true
                    font.pixelSize: 14
                    color: "#22d6ca"
                    anchors.top: typeFilePrefix.top
                    anchors.left: typeFilePrefix.right
                    anchors.leftMargin: 3
                    opacity: 0
                }

                Label {
                    id: sizeFilePrefix
                    text: "Вес: "
                    font.bold: true
                    font.pixelSize: 14
                    color: "black"
                    anchors.top: typeFilePrefix.bottom
                    anchors.topMargin: 8
                    anchors.left: typeFilePrefix.left
                    opacity: 0
                }
                Label {
                    id: sizeFile
                    text: model.size
                    font.bold: true
                    font.pixelSize: 14
                    color: "#22d6ca"
                    anchors.top: sizeFilePrefix.top
                    anchors.left: sizeFilePrefix.right
                    anchors.leftMargin: 3
                    opacity: 0
                }

                Item {
                    id: icon
                    width: height
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.bottom: fileName.top
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        id: mask
                        anchors.fill: parent
                        visible: false
                        color: colorImage
                    }
                    OpacityMask {
                        anchors.fill: mask
                        source: mask
                        maskSource: image
                    }
                    Image {
                        id: image
                        smooth: true
                        visible: false
                        source: getImage(model.type)
                    }
                }
                TextInput {
                    property string name: ""
                    id: fileName
                    maximumLength: 10
                    text: model.name
                    enabled: !mode && !selected
                    validator: RegularExpressionValidator { regularExpression: /^[A-Za-zА-Яа-я0-9_-]+$/ }
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    font.bold: true
                    font.pixelSize: 14
                    color: "black"
                    Keys.onPressed: (event) => {
                        if(event.key === 16777220) {
                            fileName.focus = false
console.log(model.index)
                        }
                    }
                    onFocusChanged: {
console.log("focused")
                        if(fileName.focus) name = fileName.text
                        if(!fileName.focus && name != fileName.text) {
                            if(fileName.length > 0) {
console.log("renameFile " + model.index)
                                renameFile(model.path, fileName.text);
                            }
                            else fileName.text = name
                        }
                    }
                    MouseArea {
                        id: mouseAreaFileName
                        enabled: !mode && !selected
                        anchors.fill: fileName
                        hoverEnabled: true
                        onClicked: if(!mode && !selected) fileName.forceActiveFocus()
                    }
                }
                Rectangle {
                    anchors.centerIn: fileName
                    height: fileName.height + 5
                    width: fileName.width + 6
                    color: mouseAreaFileName.containsMouse ? "#10000000" : "transparent"
                    radius: 5
                    border.width: 1
                    border.color: fileName.focus ? "#29b365" : "transparent"
                }
            }
        }
    }
    ScrollView {
        visible: false
        id: fieldText
        width: parent.width
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: ScrollBar {
            id: control
            parent: fieldText
            x: fieldText.mirrored ? 0 : fieldText.width - width
            y: fieldText.topPadding
            height: fieldText.availableHeight
            background: Rectangle {
                color: colorPage
            }
        }

        TextArea {
            property bool limiter: false
            id: textArea
            width: parent.width
            font.pixelSize: 18
            wrapMode: Text.Wrap
            color: "#e6e6e6"
            background: Rectangle { color: "transparent" }
            Keys.onPressed: (event)=> {
                if (event.key == Qt.Key_Escape) {
                    textArea.focus = false
                    if(text.trim() === "") {
                        if(stackView.currentItem != mainWindow) {
                            touchField.enabled = true
                            stackView.replace(mainWindow)
                        }
                    }
                    event.accepted = true;
                }
            }
            onLengthChanged: {
                if(text.trim() === "" && limiter) {
console.log("text limiter false")
                    limiter = false
                    changedReadyState(false)
                }
                if(text.trim() !== "" && !limiter) {
console.log("text limiter true")
                    limiter = true
                    changedReadyState(true)
                }
            }
        }
        Rectangle {
            z:-1
            id: textBox
            anchors.top: parent.top
            width: textArea.width
            height: parent.height
            color: colorTextBoxes
            radius: 10
        }
//        Label {
//            id: sizeTextArea
//            text: textArea.length
//            font.italic: true
//            font.pixelSize: 14
//            color: textArea.length > 0 ? "lightgreen" : "red"
//            anchors.top: textBox.bottom
//            anchors.right: textBox.right
//            anchors.rightMargin: 20
//        }
    }
    MouseArea {
        id: touchField
        anchors.fill: parent
        onDoubleClicked: {
console.log("touchField");
            fileDialog.open()
        }
    }
    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFiles
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            addFiles(fileDialog.files)
        }
    }
}
