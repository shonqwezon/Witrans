import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects

Page {
    id: root
    property alias colorPage: backColor.color
    property color colorSwitchLayout: "#40FFFFFF"
    property color colorSwitch: "black"
    property color colorBorder: "transparent"
    property color colorIndicateProcess: "#80ff80"
    property color colorAccept: "#6095e695"
    property color colorReject: "#60ff9999"
    property color colorExtra: "#609999ff"
    property int indentSwitch: 8

    property bool switchMode: true
    property bool progressAnim: false
    property alias dataMode: switchItem.visible
    property string g_EventDataButton

    property double coef3Btn: 3.8
    property double coef2Btn: 3.0

    property var selectedList: []
    property var notificationList: []
    property var subjectsList: new Map()
    property var finishedList: []

    property var uploadsList: new Map()
    property var loadedList: []

    property string upl: "upl"
    property string downl: "downl"

    function display() {
        console.log(JSON.stringify([...subjectsList.entries()]))
    }

    property var btnMode: {'file': "file", 'text': "text", 'finished': "finished", 'cancel': "cancel", 'stop': "stop", 'clear':"clear"}
    property bool safeFinishedOperate: true

    signal openTab(string handle)
    signal sendFile(string handle, string type)

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

    function selectEntry(eventMode) {
        if(dataMode) dataMode = false
        console.log(eventMode)
        g_EventDataButton = eventMode
        switch(eventMode) {
            case btnMode.file:
                acceptButton.label = qsTr("Принять")
                rejectButton.label = qsTr("Отклонить")
                break;
            case btnMode.text:
                acceptButton.label = qsTr("Копировать")
                rejectButton.label = qsTr("Удалить")
                break;
            case btnMode.finished:
                acceptButton.label = qsTr("Открыть файл")
                rejectButton.label = qsTr("Удалить")
                extraButton.label = qsTr("Отркыть папку")
                break;
            case btnMode.cancel:
                rejectButton.label = qsTr("Отменить")
                break;
            case btnMode.stop:
                rejectButton.label = qsTr("Остановить")
                break;
            case btnMode.clear:
                rejectButton.label = qsTr("Очистить")
                break;
            default:
                console.log("Error event mode")
                break;
        }
    }
    function clearEntry() {
        if(!dataMode) {
            dataMode = true
        }
    }

    Rectangle {
        z: 2
        id: switchLayout
        width: parent.width - 2*40
        height: 40
        radius: height / 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 25
        anchors.horizontalCenter: parent.horizontalCenter
        color: colorSwitchLayout
        border.width: 1
        border.color: mouseAreaSwitchItem.containsPress ? colorBorder : "transparent"

        RowLayout {
            id: rowEventDataButtons
            anchors.fill: parent
            EventDataButton {
                id: acceptButton
                visible: ((g_EventDataButton != btnMode.cancel && g_EventDataButton != btnMode.stop && g_EventDataButton != btnMode.clear) && !dataMode)
                Layout.alignment: Qt.AlignHCenter
                colorBackground: colorAccept
                width: extraButton.visible ? parent.width / coef3Btn : parent.width / coef2Btn
                height: parent.height - indentSwitch
                radius: height / 1.8
                onClickedButton: {
                    switch(g_EventDataButton) {
                        case btnMode.file:
                            console.log("acceptButton g_EventDataButton = file")
                            selectedList.forEach(item => {
                                acceptFile(item.ip, item.token, item.key, item.name, item.realSize)
                            })
                            removeSelection(downl, -1)
                            break;
                        case btnMode.text:
                            console.log("acceptButton g_EventDataButton = text")
                            acceptMessage(selectedList[2])
                            break;
                        case btnMode.finished:
                            console.log("acceptButton g_EventDataButton = finished")
                            openFile(selectedList[2])
                            removeFinishedEntry(selectedList[1], downl)
                            break;
                        default:
                            console.log("acceptButton no has g_EventDataButton")
                            break;
                    }
                    clearEntry()
                    selectedList = []
                }
            }
            EventDataButton {
                id: rejectButton
                visible: !dataMode
                Layout.alignment: Qt.AlignHCenter
                colorBackground: colorReject
                width: extraButton.visible ? parent.width / coef3Btn : parent.width / coef2Btn
                height: parent.height - indentSwitch
                radius: height / 1.8
                onClickedButton: {
                    switch(g_EventDataButton) {
                        case btnMode.file:
                            console.log("rejectButton g_EventDataButton = file")
                            selectedList.forEach(item => {
                                rejectFile(item.ip, item.token, item.key);
                                removeModel(item.ip, item.token, item.key, downl);
                            })
                            removeSelection(downl, -1)
                            break;
                        case btnMode.text:
                            console.log("rejectButton g_EventDataButton = text")
                            for(let i = 1; i < dataDownloadModel.count; i++) {
                                if(dataDownloadModel.get(i).selected) {
                                    dataDownloadModel.remove(i)
                                    break;
                                }
                            }
                            removeSelection(downl, -1)
                            break;
                        case btnMode.clear:
                            console.log("rejectButton g_EventDataButton = clear")
                            if(stackView.currentItem == pageDownload) {
                                if(dataDownloadModel.get(0).ungrouped) ungroupSubjects(false, dataDownloadModel.get(0).token)
                                dataDownloadModel.get(0).size = "0"
                                finishedList = []
                                removeSelection(downl, -1)
                            }
                            else if(stackView.currentItem == pageUpload) {
                                if(dataUploadModel.get(0).ungrouped) ungroupSubjects(false, dataUploadModel.get(0).ip)
                                dataUploadModel.get(0).size = "0"
                                loadedList = []
                                removeSelection(upl, -1)
                            }

                            break;
                        case btnMode.finished:
                            console.log("rejectButton g_EventDataButton = finished")
                            removeFinishedEntry(selectedList[1], downl)
                            removeSelection(downl, -1)
                            break;
                        case btnMode.cancel:
                            console.log("rejectButton g_EventDataButton = cancel")
                            if(stackView.currentItem == pageUpload) {
                                selectedList.forEach(item => {
                                    cancelRequest(item.ip, item.token, item.key);
                                    removeModel(item.ip, item.token, item.key, upl);
                                })
                                removeSelection(upl, -1)
                            }
                            break;
                        case btnMode.stop:
                            console.log("rejectButton g_EventDataButton = stop")
                            stopFile((stackView.currentItem == pageDownload), selectedList[1].ip, selectedList[1].token, selectedList[1].key)
                            removeSelection((stackView.currentItem == pageDownload) ? downl : upl, -1)
                            break;
                        default:
                            console.log("rejectButton no has g_EventDataButton")
                            break;
                    }
                    clearEntry()
                    selectedList = []
                }
            }
            EventDataButton {
                id: extraButton
                visible: (g_EventDataButton == btnMode.finished && !dataMode)
                Layout.alignment: Qt.AlignHCenter
                colorBackground: colorExtra
                width: extraButton.visible ? parent.width / coef3Btn : parent.width / coef2Btn
                height: parent.height - indentSwitch
                radius: height / 1.8
                onClickedButton: {
                    switch(g_EventDataButton) {
                        case btnMode.finished:
                            console.log("extraButton g_EventDataButton = finished")
                            openDirectory(selectedList[2])
                            removeFinishedEntry(selectedList[1], downl)
                            break;
                        default:
                            console.log("extraButton no has g_EventDataButton")
                            break;
                    }
                    clearEntry()
                    selectedList = []
                }
            }
        }

        Rectangle {
            id: switchItem
            width: parent.width / 2.5 - 2*indentSwitch
            height: parent.height - 2*indentSwitch
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: mouseAreaSwitchItem.containsMouse ? Qt.darker(colorSwitch, 1.1) : colorSwitch

            Component.onCompleted: {
                switchItem.x = indentSwitch
            }

            MouseArea {
                enabled: parent.enabled
                id: mouseAreaSwitchItem
                anchors.fill: parent
                hoverEnabled: true

                onPressedChanged: {
                    if(containsPress) {
                        indentSwitch -= 2
                        progressAnim = false
                    }
                    else {
                        indentSwitch += 2
                    }
                }
                onMouseXChanged: {
                    if(!progressAnim) {
                        if(switchMode && mouseX >= (switchLayout.width - switchItem.width - indentSwitch)) {
                            animSwitchItem.start()
                        }
                        if(!switchMode && mouseX <= (2 * switchItem.width - switchLayout.width)) {
                            animSwitchItem.start()
                        }
                    }
                }
            }

            NumberAnimation {
                id: animSwitchItem
                target: switchItem
                property: "x"
                duration: 300
                easing.type: Easing.InOutQuad
                to: switchMode ? switchLayout.width - switchItem.width - indentSwitch : indentSwitch
                onStarted: {
                    progressAnim = true
                    switchMode = !switchMode
                    labelFirstWindow.opacity = switchMode ? 1 : 0
                    labelSecondWindow.opacity = switchMode ? 0 : 1
                }
                onFinished: {
                    if(switchMode) {
                        stackView.replace(pageDownload)
                    }
                    else {
                        if(!pageUpload.visible) pageUpload.visible = true
                        stackView.replace(pageUpload)
                    }
                }
            }
        }

        Item {
            id: leftAnchor
            anchors.verticalCenter: parent.verticalCenter
            x: indentSwitch + switchItem.width / 2
        }
        Label {
            id: labelSecondWindow
            visible: dataMode
            anchors.centerIn: leftAnchor
            font.pixelSize: 18
            font.bold: true
            color: "white"
            text: qsTr("Текущие процессы")
            opacity: 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
        Item {
            id: rightAnchor
            anchors.verticalCenter: parent.verticalCenter
            x: switchLayout.width - indentSwitch - switchItem.width / 2
        }
        Label {
            id: labelFirstWindow
            visible: dataMode
            anchors.centerIn: rightAnchor
            font.pixelSize: 18
            font.bold: true
            color: "white"
            text: qsTr("Запросы")
            opacity: 1
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
    }
    Rectangle {
        z: 1
        id: bottomHidden
        color: colorPage
        anchors.centerIn: switchLayout
        height: switchLayout.height
        width: switchLayout.width
        radius: height / 2
    }

    StackView {
        id: stackView
        initialItem: pageDownload
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
    }
    ListModel {
        id: dataDownloadModel
        ListElement {
             ungrouped: false
             selectedCount: 0
             selected: false
             processCount: 0
             process: false
             startTime: ""
             indicatorStatus: 0
             token: "finished"
             ip: ""
             user: "users"
             type: "files"
             body: "Скаченные файлы"
             size: "0"
             key: ""
             realSize: ""
        }
    }
    ListModel {
        id: dataUploadModel
        ListElement {
            ungrouped: false
            selectedCount: 0
            selected: false
            processCount: 0
            process: false
            startTime: ""
            indicatorStatus: 0
            token: "loaded"
            ip: ""
            user: "users"
            type: "files"
            body: "Отправленные файлы"
            size: "0"
            key: ""
            path: ""
        }
    }


    signal cancelRequest(string ip, string token, string key)
    signal stopFile(bool download, string ip, string token, string key)

    signal startOperationFile(bool download, string token, string key)
    signal changedProgressFile(bool download, string token, string key, int progressStatus)
    signal endDownloadFile(string token, string key, string finishedTime, string filePath)

    signal removeModel(string ip, string token, string key, string modelType)
    onRemoveModel: (ip, token, key, modelType) => {
        if(key == "" && token == "") {
console.log("D delete files (disconnect)")
          selectedList.forEach((item, index) => {
              if(item.ip == ip) selectedList.splice(index, 1)
          })
        }
        else {
            if(!modelType) {
console.log("delete file from selectedList")
                let itemId = selectedList.findIndex(item => item.ip == ip && item.token == token && item.key == key)
                if(itemId != -1) selectedList.splice(itemId, 1)
            }
        }
console.log("selectedList size", selectedList.length)
        if(selectedList.length == 0) clearEntry()
    }
    function removeFinishedEntry(key, modelType) {
        if(modelType == downl) {
            let entryId = finishedList.findIndex(i => i.key == key)
            if(dataDownloadModel.get(0).ungrouped && !(finishedList.length - 1)) {
                ungroupSubjects(false, dataDownloadModel.get(0).token)
            }
            else dataDownloadModel.remove(entryId + 1)
            finishedList.splice(entryId, 1)
            dataDownloadModel.get(0).size = finishedList.length.toString()
        }
        else if(modelType == upl) {
            let entryId = loadedList.findIndex(i => i.key == key)
            if(dataUploadModel.get(0).ungrouped && !(loadedList.length - 1)) {
                ungroupSubjects(false, dataUploadModel.get(0).token)
            }
            else dataUploadModel.remove(entryId + 1)
            loadedList.splice(entryId, 1)
            dataUploadModel.get(0).size = loadedList.length.toString()
        }
    }

    signal ungroupSubjects(bool state, string token)
    signal removeSelection(string modelType, int index)
    signal selectSubjects(bool mode, string token)
    signal setSelectSubject(bool mode, string handle)

    function appendUploadModel(type, ip, user, size, list) {
        if(!uploadsList.has(ip)) {
            dataUploadModel.append({ungrouped: false, selectedCount: 0, selected: false, processCount: 0, process: false, startTime: "", indicatorStatus: 0, token: "", ip: ip, user: user, type: "files", size: size})
        }
        console.log("append Upload model", type, ip, user, size, list)
        let token = list[0][0];
        list.forEach(item => {
            if(item != token) {
                let subject = {selected: false, process: false, startTime: "", indicatorStatus: 0, token: token, type: item[1], body: item[2], size: item[4], path: item[5]}
                if(!uploadsList.has(ip)) {
                    let m_list = {}
                    m_list[item[0]] = subject
                    uploadsList.set(ip, m_list)
                }
                else {
                    uploadsList.get(ip)[item[0]] = subject
                }
            }
        })
        for(let i = 0; i < dataUploadModel.count; i++) {
            if(dataUploadModel.get(i).ungrouped && dataUploadModel.get(i).ip == ip) {
                list.forEach((item, index) => {
                    if(item != token) {
                        dataUploadModel.insert(i + index + 1, {
                                                  selected: false,
                                                  process: false,
                                                  startTime: "",
                                                  indicatorStatus: 0,
                                                  token: token,
                                                  ip: ip,
                                                  user: user,
                                                  type: item[1],
                                                  body: item[2],
                                                  size: item[4],
                                                  key: item[0],
                                                  path: item[5]
                                              })
                    }
                })
            }
        }

        console.log(Object.keys(uploadsList.get(ip)).length, JSON.stringify([...uploadsList.entries()]))
    }

    property int denom_UP: 21
    property int sizeDirect_UP: 4
    property int sizeType_UP: 2
    property int sizeName_UP: 9
    property int sizeSize_UP: 4
    property int sizeMode_UP: 2

    Item {
        id: pageUpload
        visible: false

        ListView {
            id: tableViewUpload
            anchors.fill: parent
            anchors.bottomMargin: 55
            boundsBehavior: Flickable.StopAtBounds
            spacing: 3

            model: dataUploadModel
            header: Item {
                width: parent.width
                height: headerUpload.height + headerUploadBottom.height + 12
                Row {
                    id: headerUpload
                    height: 30
                    width: parent.width

                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * sizeDirect_UP - 1
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Запрос к")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * sizeType_UP - 1
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Тип")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * sizeName_UP - 1
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Наименование")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * (sizeSize_UP + sizeMode_UP)
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Размер")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                }
                Rectangle {
                    id: headerUploadBottom
                    color: "white"
                    height: 2
                    radius: height / 2
                    width: headerUpload.width - 20
                    anchors.top: headerUpload.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: headerUpload.horizontalCenter
                }
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
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

            delegate: Rectangle {
                id: itemDelegateUpload
                implicitHeight: 30
                implicitWidth: tableViewUpload.width
                color: model.selected ? itemDelegateUpload.color = Qt.darker(colorSwitchLayout, 1.4) : Qt.darker(colorPage, 1.2)
                radius: implicitHeight / 2

                Connections {
                    target: root

                    function onUngroupSubjects(state, ip) {
                        if((ip == model.ip && model.token != dataUploadModel.get(0).token) || (ip == dataUploadModel.get(0).ip && model.token == dataUploadModel.get(0).token)) {
                            if(model.type == "files") {
                                moreFilesButtonU.rotation -= 90
                                mouseAreaUngroupU.state = !mouseAreaUngroupU.state
                                model.ungrouped = state
                                if(model.token == dataUploadModel.get(0).token && state) {
                                    loadedList.forEach((item, i) => {
                                        dataUploadModel.insert(model.index + i + 1, {
                                                               selected: item.selected,
                                                               startTime: item.startTime,
                                                               token: model.token,
                                                               ip: item.ip,
                                                               user: item.user,
                                                               type: item.type,
                                                               body: item.body,
                                                               size: item.size,
                                                               key: item.key,
                                                               path: item.path
                                                           })
                                    })
                                }
                                else {
                                    if(state) {
                                        processIndicatorU.state = "hide"
                                        let subjects = uploadsList.get(model.ip)
                                        Object.keys(subjects).forEach((key, i) => {
                                            dataUploadModel.insert(model.index + i + 1, {
                                                                      selected: subjects[key].selected,
                                                                      process: subjects[key].process,
                                                                      startTime: subjects[key].startTime,
                                                                      indicatorStatus: subjects[key].indicatorStatus,
                                                                      token: subjects[key].token,
                                                                      ip: model.ip,
                                                                      user: model.user,
                                                                      type: subjects[key].type,
                                                                      body: subjects[key].body,
                                                                      size: subjects[key].size,
                                                                      key: key,
                                                                      path: subjects[key].path
                                                                  })
                                        })
                                    }
                                    else {
                                        if(model.process) processIndicatorU.state = "show"
                                    }
                                }
                            }
                            else {
                                if(!state) {
                                    dataUploadModel.remove(model.index)
                                }
                            }
                        }
                    }
                    function onSelectSubjects(mode, ip) {
                        if(model.ip == ip || (ip == dataUploadModel.get(0).ip && model.token == dataUploadModel.get(0).token)) {
                            if(model.type == "files") {
                                if(model.token == dataUploadModel.get(0).token) {
                                    if(mode && loadedList.length) selectedList = [model.token]
                                    loadedList.forEach(item => {
                                        item.selected = mode
                                    })
console.log("SelectSubjects: Finished list")
                                }
                                else {
                                    let selCount = 0
                                    let subjects = uploadsList.get(model.ip)
                                    Object.keys(subjects).forEach(key => {
                                        if(!subjects[key].startTime.length) {
                                          if(mode) {
                                              if(selectedList.findIndex(item => item.ip == model.ip && item.key == key) == -1) {
                                                  selectedList.push({ip: model.ip,
                                                                        token: subjects[key].token,
                                                                        key: key,
                                                                        name: subjects[key].body+"."+subjects[key].type
                                                                    })
                                              }
                                              selCount++
                                          }
//console.log(subjects[key].body, subjects[key].process)
                                          subjects[key].selected = mode
                                        }
                                    })
                                    model.selectedCount = selCount
                                }
                            }
                            else {
                                if(!model.startTime.length || model.token == dataUploadModel.get(0).token) {
                                    itemDelegateUpload.color = mode ? Qt.darker(colorSwitchLayout, 1.4) : Qt.darker(colorPage, 1.2)
                                    model.selected = mode
                                }
                            }
                        }
                    }
                    function onSetSelectSubject(mode, ip) {
                        if(model.ip == ip && model.type == "files") {
                            if(mode) {
                                model.selectedCount += 1
                                if(model.selectedCount == Object.keys(uploadsList.get(model.ip)).length) {
                                    model.selected = true
                                    itemDelegateUpload.color = Qt.darker(colorSwitchLayout, 1.2)
                                }
                            }
                            else {
                                if(model.selectedCount == Object.keys(uploadsList.get(model.ip)).length) {
                                    model.selected = false
                                    itemDelegateUpload.color = Qt.darker(colorPage, 1.2)
                                }
                                model.selectedCount -= 1
                            }
                        }
                    }

                    function onRemoveModel(ip, token, key, modelType) {
                        if(model.ip == ip && token == "" && key == "") {                 //disconnect
console.log("U delete disconnect", model.body)
                            if(uploadsList.has(model.ip)) uploadsList.delete(model.ip)
                            dataUploadModel.remove(model.index)
                        }
                        else {
                            if(modelType == upl) {
                                console.log("onRemoveUploadModel", ip, token, key, uploadsList.size)
                                if(model.ip == ip && key != "") {   //delete file
                                    if(model.type == "files") {
                                        model.selectedCount--
                                        delete uploadsList.get(model.ip)[key]
                                        if(!Object.keys(uploadsList.get(model.ip)).length) {
        console.log("U delete group of files because of its empty", model.index)
                                            uploadsList.delete(model.ip)
                                            dataUploadModel.remove(model.index)
                                        }
                                    }
                                    else {
                                        if(model.key == key && model.token == token) {
                                            dataUploadModel.remove(model.index)
                                        }
                                    }
                                }
                                else if(model.ip == ip && model.ip == token && key == "") {   //delete files
        console.log("delete files")
                                    cancelRequest(model.ip, model.token, model.key)
                                    if(uploadsList.has(model.ip)) uploadsList.delete(model.ip)
                                    dataUploadModel.remove(model.index)
                                }
                            }
                        }
                    }
                    function onRemoveSelection(modelType, index) {
                        if(modelType == upl) {
                            if(model.index != index) {
                                if(model.type == "files") {
                                    model.selected = false
                                    itemDelegateUpload.color = Qt.darker(colorPage, 1.2)
                                    if(model.token == dataUploadModel.get(0).token) {
                                        loadedList.forEach(item => {
                                                                item.selected = false
                                                             })
                                    }
                                    else selectSubjects(false, model.ip)
                                }
                                else if(model.type == "text") {
                                    model.selected = false
                                    itemDelegateUpload.color = Qt.darker(colorPage, 1.2)
                                }
                                else {
                                    model.selected = false
                                    if(uploadsList.has(model.ip) && model.token != dataUploadModel.get(0).token) {
                                        uploadsList.get(model.ip)[model.key].selected = false
                                    }
                                    itemDelegateUpload.color = Qt.darker(colorPage, 1.2)
                                }
                            }
                        }
                    }

                    function onStartOperationFile(download, ip, key) {
                        if(!download && model.ip == ip) {
                            if(model.type == "files") {
                                if(!model.process) {
                                    console.log("run mode files start")
                                    model.process = true
                                    if(!model.ungrouped) processIndicatorU.state = "show"
                                }
                                let subjects = uploadsList.get(model.ip)[key]
                                if(!subjects.process) {
                                    subjects.startTime = new Date().toString()
                                    subjects.process = true
                                    model.processCount++
console.log("start 1", subjects.body)
                                }
                            }
                            else {
                                if(model.key == key) {
                                    model.startTime = new Date().toString()
                                    model.process = true
console.log("start 2", model.body)
                                }
                            }
                        }
                    }
                    function onChangedProgressFile(download, ip, key, progressStatus) {
                        if(!download && model.ip == ip) {
                            if(model.type == "files" && !model.ungrouped) {
                                if(progressStatus == -1) {
                                    model.processCount--;
                                    model.process = (model.processCount != 0)
                                    if(!model.process) processIndicatorU.state = "hide"

                                    uploadsList.get(model.ip)[key].startTime = ""
                                    uploadsList.get(model.ip)[key].process = false
                                    uploadsList.get(model.ip)[key].indicatorStatus = 0
                                } else
                                    uploadsList.get(model.ip)[key].indicatorStatus = progressStatus
                            }
                            else {
                                if(model.key == key) {
                                    if(progressStatus == -1) {
                                        timeLabelU.text = model.size
                                        model.startTime = ""
                                        model.process = false
                                        model.indicatorStatus = 0
                                    } else
                                        model.indicatorStatus = progressStatus
//console.log("change 2", model.body)
                                }
                            }
                        }
                    }
                    function onEndDownloadFile(ip, key, finishedTime, filePath) {
                        if(model.ip == ip) {
                            removeModel(model.ip, token, key, "")
                            if(model.type == "files") {
                                let subjects = uploadsList.get(model.ip)[key]
                                removeModel(ip, subjects.token, key, "")

                                let item = {selected: false, startTime: finishedTime, ip: ip, user: model.user, type: subjects.type, body: subjects.body, size: subjects.size, key: key, path: subjects.path}
                                loadedList.push(item)
                                dataUploadModel.get(0).size = loadedList.length.toString()
                                if(dataUploadModel.get(0).ungrouped) {
                                    item["token"] = dataDownloadModel.get(0).token
                                    dataUploadModel.insert(loadedList.length.toString(), item)
                                }
console.log("end 1", subjects.body)
                                model.selectedCount--
                                delete uploadsList.get(model.ip)[key]
                                model.processCount--;
                                model.process = (model.processCount != 0)
                                if(!model.process) processIndicatorU.state = "hide"
console.log(loadedList.length.toString(), JSON.stringify(loadedList))
                                if(!Object.keys(uploadsList.get(model.ip)).length) {
                                    uploadsList.delete(model.ip)
                                    dataUploadModel.remove(model.index)
                                }
                            }
                            else {
                                if(model.key == key) {
                                    if(!uploadsList.has(model.ip) && loadedList.findIndex(i => i.key == model.key) == -1) {
                                        let item = {selected: false, startTime: finishedTime, ip: ip, user: model.user, type: model.type, body: model.body, size: model.size, key: key, path: subjects.path}
                                        loadedList.push(item)
                                        dataUploadModel.get(0).size = loadedList.length.toString()
                                        if(dataUploadModel.get(0).ungrouped) {
                                            item["token"] = dataUploadModel.get(0).token
                                            dataUploadModel.insert(loadedList.length.toString(), item)
                                        }
                                    }
                                    console.log("end 2", model.body)
                                    dataUploadModel.remove(model.index)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    property int indicatorWidth: itemDelegateUpload.width / 100 * model.indicatorStatus
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    color: colorIndicateProcess
                    opacity: 0.4
                    radius: parent.radius
                    height: parent.height
                    width: indicatorStatus == 100 && !animIndicator.running ? parent.width : indicatorWidth

                    Behavior on indicatorWidth {
                        NumberAnimation {
                            id: animIndicator
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                Rectangle {
                    id: processIndicatorU
                    visible: true
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: 0.0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 1.0
                            color: itemDelegateUpload.color
                        }
                        GradientStop {
                            id: gradU
                            position: 0.0
                            color: "#bdffb3"
                        }
                        GradientStop {
                            position: 0.0
                            color: itemDelegateUpload.color
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }
                    states: [
                        State {
                            name: "show"
                            PropertyChanges {
                                target: processIndicatorU
                                opacity: 0.3
                            }
                        },
                        State {
                            name: "hide"
                            PropertyChanges {
                                target: processIndicatorU
                                opacity: 0.0
                            }
                        }
                    ]

                    NumberAnimation {
                        duration: 2000
                        running: model.process && !model.ungrouped && model.type == "files"
                        property: "position"
                        target: gradU
                        from: 0.0
                        to: 1.0
                        easing.type: Easing.InOutQuad
                        onFinished: {
                            let temp = to
                            to = from
                            from = temp
                            running = true
                        }
                    }
                }

                Timer {
                    interval: 1
                    running: model.process && model.type != "files"
                    repeat: true
                    onTriggered: timeLabelU.text = Qt.formatDateTime(new Date(new Date() - new Date(model.startTime)), "mm:ss.zzz");
                }

                MouseArea {
                    enabled: parent.enabled
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                                   if(mouse.button == Qt.LeftButton) {
                                       if((selectedList[0] == dataUploadModel.get(0).token && model.token != dataUploadModel.get(0).token) ||
                                          (selectedList[0] == btnMode.stop) ||
                                          (model.process && model.token != dataUploadModel.get(0).token)) {
                                           console.log("clear SELECTION")
                                           removeSelection(upl, model.index)
                                           selectedList = []
                                       }
                                       if(model.type == "files") {
                                           if(!model.selected) {
                                               console.log("U selected group (1) " + model.index)
                                               if(model.token == dataUploadModel.get(0).token) {
                                                   if(loadedList.length) selectEntry(btnMode.clear)
                                               }
                                               else {
                                                    if(Object.keys(uploadsList.get(model.ip)).length - model.processCount)
                                                        selectEntry(btnMode.cancel)
                                               }
                                           }
                                           else {
                                               console.log("U unselected group (1) " + model.index)
                                               if(model.token == dataUploadModel.get(0).token) {
                                                    selectedList = []
                                               }
                                               else {
                                                   let entryId = selectedList.findIndex(i => i.ip == model.ip)
                                                   while(entryId != -1) {
                                                       selectedList.splice(entryId, 1)
                                                       entryId = selectedList.findIndex(i => i.ip == model.ip)
                                                   }
                                               }
                                           }
                                           selectSubjects(!model.selected, model.ip)
                                       }
                                       else {
                                           if(!model.selected) {
                                               if(model.token != dataDownloadModel.get(0).token) {
                                                   console.log("U selected file (1) " + model.index)
                                                   if(model.token == dataDownloadModel.get(0).token)
                                                       selectEntry(btnMode.clear)
                                                   else {
                                                       if(model.process) {
                                                            selectedList = [btnMode.stop]
                                                            selectEntry(btnMode.stop)
                                                       }
                                                       else selectEntry(btnMode.cancel)
                                                   }
                                                   itemDelegateUpload.color = Qt.darker(colorSwitchLayout, 1.4)
                                                   if(model.token == dataUploadModel.get(0).token) {
                                                       removeSelection(upl, model.index)
                                                       selectedList = [dataUploadModel.get(0).token, model.key, model.ip]
                                                   }
                                                   else selectedList.push({ip: model.ip, token: model.token, key: model.key, name: model.body+"."+model.type})
                                               }
                                           }
                                           else {
                                                console.log("U unselected file (1) " + model.index)
                                                if(selectedList[0] != dataUploadModel.get(0).token) {
                                                   console.log("e3")
                                                   itemDelegateUpload.color = Qt.darker(colorSwitchLayout, 1.2)
                                                   let entryId = selectedList.findIndex(i => i.token == model.token && i.key == model.key)
                                                   selectedList.splice(entryId, 1)
                                                }
                                           }
                                           if(model.token != dataUploadModel.get(0).token) {
                                               if(selectedList[0] != btnMode.stop) setSelectSubject(!model.selected, model.ip)
                                               if(uploadsList.has(model.ip))
                                                   uploadsList.get(model.ip)[model.key].selected = !model.selected
                                           }
                                       }

                                       console.log("current size", selectedList.length)
                                       if(model.token == dataUploadModel.get(0).token) {
                                           if(loadedList.length && model.type == "files") {
                                               model.selected = !model.selected
//                                               let entryId = loadedList.findIndex(i => i.key == model.key && i.user == model.user)
//                                               if(entryId != -1) loadedList[entryId].selected = model.selected
                                           }
                                       }
                                       else {
                                            if((Object.keys(uploadsList.get(model.ip)).length - model.processCount && model.type == "files") || (model.type != "files"))
                                                model.selected = !model.selected
                                       }

                                       if(model.selected) showingPath(false)
                                       else {
                                           if(containsMouse) {
                                                showingPath(true)
                                           }
                                       }

                                       if(!selectedList.length) clearEntry()
                                   }
                               }
                    onDoubleClicked: (mouse) => {
                        if(mouse.button == Qt.RightButton) {
                             if(model.type == "files") {
                                 if(model.token == dataUploadModel.get(0).token) {
                                     console.log("deleted loaded files (1) " + model.index)
                                     if(model.ungrouped) ungroupSubjects(false, model.ip)
                                     model.size = "0"
                                     loadedList = []
                                 }
                                 else {
                                     if(!model.process) {
                                         console.log("deleted data files (1) " + model.index)
                                         removeModel(model.ip, model.ip, "", upl);
                                     }
                                 }
                             }
                             else {
                                 if(model.token == dataUploadModel.get(0).token) {
                                     console.log("U deleted finished file (1) " + model.index)
                                     removeFinishedEntry(model.key, upl)
                                 }
                                 else {
                                     console.log("U deleted data file (1) " + model.index)
                                     cancelRequest(model.ip, model.token, model.key);
                                     removeModel(model.ip, model.token, model.key, upl);
                                 }
                             }
                             removeSelection(upl, -1)
                             clearEntry()
                             selectedList = []
                        }
                    }

                    onContainsMouseChanged: {
                        if(containsMouse) {
                            itemDelegateUpload.color = model.selected ? colorSwitchLayout : Qt.darker(colorSwitchLayout, 1.2)
                            if(firstMouse && !model.selected) {
                                showingPath(true)
                            }
                        }
                        else {
                            itemDelegateUpload.color = model.selected ? Qt.darker(colorSwitchLayout, 1.4) : Qt.darker(colorPage, 1.2)
                            showingPath(false)
                        }
                    }
                }
                property bool firstMouse: true
                function showingPath(mode) {
                    if(model.type != "files") {
                        if(mode) pathTimer.start()
                        else {
                            pathTimer.stop()
                            itemDelegateUpload.state = "hidePath"
                        }
                        firstMouse = !mode
                    }
                }

                Timer {
                    id: pathTimer
                    interval: 1000
                    repeat: false
                    onTriggered: {
                       itemDelegateUpload.state = "showPath"
                    }
                }

                states: [
                    State {
                        name: "showPath"
                        PropertyChanges {
                            target: labelPath
                            opacity: 1
                        }
                        PropertyChanges {
                            target: dataUploadDelegate
                            opacity: 0
                        }
                    },
                    State {
                        name: "hidePath"
                        PropertyChanges {
                            target: labelPath
                            opacity: 0
                        }
                        PropertyChanges {
                            target: dataUploadDelegate
                            opacity: 1
                        }
                    }
                ]
                TextInput {
                    id: labelPath
                    anchors.centerIn: parent
                    text: (model.type != "files") ? model.path : ""
                    maximumLength: 70
                    font.pixelSize: 14
                    font.bold: true
                    color: "white"
                    readOnly: true
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                Row {
                    id: dataUploadDelegate
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }

                    anchors.fill: parent
                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * sizeDirect_UP - 1
                        Label {
                            anchors.centerIn: parent
                            text: model.user
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * sizeType_UP - 1
                        Label {
                            anchors.centerIn: parent
                            text: model.type
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: parent.width / denom_UP * sizeName_UP - 1
                        TextInput {
                            anchors.centerIn: parent
                            text: (model.type == "files" && model.index != 0) ? qsTr("Всего: %1 -- Выбрано: %2").arg(Object.keys(uploadsList.get(model.ip)).length - model.processCount).arg(model.selectedCount) : model.body
                            maximumLength: 30
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                            readOnly: true
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: (model.token == "loaded" && model.type != "files") ? parent.width / denom_UP * (sizeSize_UP + sizeMode_UP) / 2 : parent.width / denom_UP * sizeSize_UP - 1
                        Label {
                            id: timeLabelU
                            anchors.centerIn: parent
                            text: model.size
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                            Component.onCompleted: {
                                if(model.startTime.length && !model.process && model.token != "finished") text = model.startTime
                                else text = model.size
                            }
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: (model.token == "loaded" && model.type != "files") ? parent.width / denom_UP * (sizeSize_UP + sizeMode_UP) / 2 : parent.width / denom_UP * sizeMode_UP
                        Label {
                            visible: model.startTime.length != 0
                            anchors.centerIn: parent
                            font.pixelSize: 14
                            font.bold: true
                            text: (model.token == "loaded") ? model.startTime : qsTr("%1%").arg(indicatorStatus)
                            color: "white"
                        }
                        Item {
                            visible: (model.type == "files")
                            anchors.centerIn: parent
                            height: parent.height - 2
                            width: height

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.height / 2
                                color: mouseAreaUngroupU.containsMouse ? "#15DCDCDC" : "transparent"
                            }

                            Rectangle {
                                id: moreFilesButtonU
                                anchors.centerIn: parent
                                height: mouseAreaUngroupU.containsPress ? parent.height - 2 * 6 : parent.height - 2 * 7
                                width: 3
                                radius: height / 2
                                color: mouseAreaUngroupU.containsPress ? Qt.darker("white", 1.2) : "white"
                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                height: 3
                                width: mouseAreaUngroupU.containsPress ? parent.height - 2 * 6 : parent.height - 2 * 7
                                radius: height / 2
                                color: mouseAreaUngroupU.containsPress ? Qt.darker("white", 1.2) : "white"
                            }

                            MouseArea {
                                id: mouseAreaUngroupU
                                property bool state: true
                                anchors.fill: parent
                                enabled: parent.enabled
                                hoverEnabled: true
                                onClicked: {
                                    if(moreFilesButtonU.rotation % 90 == 0) {
                                        if(model.token == dataUploadModel.get(0).token && !loadedList.length) {
                                            moreFilesButtonU.rotation -= 180
                                            return;
                                        }
                                        ungroupSubjects(state, model.ip)
//                                        if(g_EventDataButton == btnMode.clear && safeFinishedOperate) {
//                                            clearEntry()
//                                            removeSelection(upl, -1)
//                                            selectedList = []
//                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function appendDownloadModel(type, ip, user, size, list) {
console.log("dataDownloadModel size:", dataDownloadModel.count)
        let token = list[0][0];
        if(type == "files") {
            let subjects = {};
            list.forEach(item => {
                if(item != token) {
console.log(token, item[0], item[1], item[2], item[2], item[3], item[4])
                    subjects[item[0]] = {selected: false, process: false, startTime: "", indicatorStatus: 0, type: item[1], body: item[2], size: item[4], realSize: item[3]}
                }
            })
            subjectsList.set(token, subjects)
            console.log("subjectList size - ", subjectsList.size)
            display()
            dataDownloadModel.append({ungrouped: false, selectedCount: 0, selected: false, processCount: 0, process: false, indicatorStatus: 0, token: token, ip: ip, user: user, type: type, size: size})
        }
        else if(type == "text") {
            let index = dataDownloadModel.get(0).ungrouped ? finishedList.length + 1 : 1
            dataDownloadModel.insert(index, {selected: false, ip: ip, user: user, type: type, body: token, size: size})
        }
        else if(type == "file") {
            dataDownloadModel.append({selected: false, process: false, startTime: "", indicatorStatus: 0, token: token, ip: ip, user: user, type: list[1][1], body: list[1][2], size: size, key: list[1][0], realSize: list[1][3]})
        }
/*
        var component = Qt.createComponent("QuickResponse.qml")
        var quickResponse = component.createObject(root)
        quickResponse.handle = handle
        quickResponse.user = user
        quickResponse.type = type
        quickResponse.body = (type == "files") ? qsTr("%1 files - %2").arg(list.length).arg(size) : list[0][0]
        quickResponse.x = Screen.desktopAvailableWidth - quickResponse.width - 10
        quickResponse.y = Screen.desktopAvailableHeight - quickResponse.height - 50 - (quickResponse.height + 10) * notificationList.length

        function updateNotifPosition() {
            var id = notificationList.findIndex(item => item == quickResponse)
            notificationList.splice(id, 1)
            for(let i = id; i < notificationList.length; i++) notificationList[i].updatePosition()
        }

        quickResponse.acceptText.connect((h, t) => {
            removeDownloadModel(h, "", "")
            acceptMessage(t)
            updateNotifPosition()
        })
        quickResponse.rejectText.connect(h => { removeDownloadModel(h, "", ""); updateNotifPosition() })
        quickResponse.moreDetails.connect(h => { openTab(h); updateNotifPosition() })
        quickResponse.acceptFiles.connect((h, t) => { sendFile(h, t); updateNotifPosition()} )
        quickResponse.destroyNotif.connect(updateNotifPosition)
        notificationList.push(quickResponse)
        */
    }

    signal acceptFile(string ip, string token, string key, string name, string realSize)
    signal acceptMessage(string msg)
    signal rejectFile(string ip, string token, string key)
    signal openDirectory(string filePath)
    signal openFile(string filePath)

    property int denom_DP: 21
    property int sizeDirect_DP: 4
    property int sizeType_DP: 2
    property int sizeName_DP: 9
    property int sizeSize_DP: 4
    property int sizeMode_DP: 2

    Item {
        id: pageDownload
        ListView {
            id: tableViewDownload
            anchors.bottomMargin: 55
            anchors.fill: parent
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds

            model: dataDownloadModel
            header: Item {
                width: parent.width
                height: headerDownload.height + headerDownloadBottom.height + 12
                Row {
                    z: 2
                    id: headerDownload
                    width: parent.width
                    height: 30
                    Item {
                        id: labelDirectD
                        height: parent.height
                        width: parent.width / denom_DP * sizeDirect_DP - 1
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Запрос от")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: parent.width / denom_DP * sizeType_DP - 1
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Тип")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        height: parent.height
                        width: parent.width / denom_DP * sizeName_DP - 1
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Наименование")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        height: parent.height
                        width: parent.width / denom_DP * (sizeSize_DP + sizeMode_DP)
                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Размер")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                    }
                }
                Rectangle {
                    z: 2
                    id: headerDownloadBottom
                    color: "white"
                    height: 2
                    radius: height / 2
                    width: headerDownload.width - 20
                    anchors.top: headerDownload.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: headerDownload.horizontalCenter
                }
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
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

            delegate: Rectangle {
                id: itemDelegateDownload
                implicitHeight: 30
                implicitWidth: tableViewDownload.width
                color: model.selected ? itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.4) : Qt.darker(colorPage, 1.2)
                radius: implicitHeight / 2

                Connections {
                    target: root
                    //notif
                    function onSendFile(handle, type) {
                        if(model.handle == handle && model.type == type) {
                            if(type == "files") {
                                for(let i = 0; i < model.subjects.count; i++) {
                                    console.log("Accept files page")
                                    acceptFile(handle, model.subjects.get(i).ip + " " + model.subjects.get(i).body, model.subjects.get(i).size)
                                }
                            }
                            else {
                                acceptFile(handle, model.ip + " " + model.body, model.size)
                                console.log("Accept file page", handle, model.ip + " " + model.body, model.size)
                            }
                            removeModel(handle, "", "", downl)
                        }
                    }
                    //notif
                    function onOpenTab(handle) {
                        if(model.handle == handle) {
                            itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.2)
                        }
                    }

                    function onUngroupSubjects(state, token) {
                        if(model.token == token) {
                            if(model.type == "files") {
                                moreFilesButtonD.rotation -= 90
                                mouseAreaUngroupD.state = !mouseAreaUngroupD.state
                                model.ungrouped = state
                                if(model.token == dataDownloadModel.get(0).token && state) {
                                    finishedList.forEach((item, i) => {
                                        dataDownloadModel.insert(model.index + i + 1, {
                                                               selected: item.selected,
                                                               startTime: item.startTime,
                                                               token: model.token,
                                                               ip: item.ip,
                                                               user: item.user,
                                                               type: item.type,
                                                               body: item.body,
                                                               size: item.size,
                                                               key: item.key
                                                           })
                                    })
                                }
                                else {
                                    if(state) {
                                        processIndicatorD.state = "hide"
                                        let subjects = subjectsList.get(model.token)
                                        Object.keys(subjects).forEach((key, i) => {
                                        dataDownloadModel.insert(model.index + i + 1, {
                                                                  selected: subjects[key].selected,
                                                                  process: subjects[key].process,
                                                                  startTime: subjects[key].startTime,
                                                                  indicatorStatus: subjects[key].indicatorStatus,
                                                                  token: model.token,
                                                                  ip: model.ip,
                                                                  user: model.user,
                                                                  type: subjects[key].type,
                                                                  body: subjects[key].body,
                                                                  size: subjects[key].size,
                                                                  key: key,
                                                                  realSize: subjects[key].realSize
                                                              })
                                        })
                                    }
                                    else {
                                        if(model.process) processIndicatorD.state = "show"
                                    }
                                }
                            }
                            else {
                                if(!state) {
                                    dataDownloadModel.remove(model.index)
                                }
                            }
                        }
                    }
                    function onSelectSubjects(mode, token) {
                        if(model.token == token) {
                            if(model.type == "files") {
                                if(model.token == dataDownloadModel.get(0).token) {
                                    if(mode && finishedList.length) selectedList = [model.token]
                                    finishedList.forEach(item => {
                                        item.selected = mode
                                    })
console.log("SelectSubjects: Finished list")
                                }
                                else {
                                    let selCount = 0
                                    let subjects = subjectsList.get(model.token)
                                    Object.keys(subjects).forEach(key => {
                                        if(!subjects[key].startTime.length) {
                                          if(mode) {
                                              if(selectedList.findIndex(item => item.token == model.token && item.key == key) == -1) {
                                                  selectedList.push({ip: model.ip,
                                                                        token: model.token,
                                                                        key: key,
                                                                        name: subjects[key].body+"."+subjects[key].type,
                                                                        realSize: subjects[key].realSize
                                                                    })
                                              }
                                              selCount++
                                          }
//console.log(subjects[key].body, subjects[key].process)
                                          subjects[key].selected = mode
                                        }
                                    })
                                    model.selectedCount = selCount
                                }
                            }
                            else {
                                if(!model.startTime.length || model.token == dataDownloadModel.get(0).token) {
                                    itemDelegateDownload.color = mode ? Qt.darker(colorSwitchLayout, 1.4) : Qt.darker(colorPage, 1.2)
                                    model.selected = mode
                                }
                            }
                        }
                    }
                    function onSetSelectSubject(mode, token) {
                        if(model.token == token && model.type == "files") {
                            if(mode) {
                                model.selectedCount += 1
                                if(model.selectedCount == Object.keys(subjectsList.get(model.token)).length) {
                                    model.selected = true
                                    itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.2)
                                }
                            }
                            else {
                                if(model.selectedCount == Object.keys(subjectsList.get(model.token)).length) {
                                    model.selected = false
                                    itemDelegateDownload.color = Qt.darker(colorPage, 1.2)
                                }
                                model.selectedCount -= 1
                            }
                        }
                    }

                    function onRemoveModel(ip, token, key, modelType) {
                        if(model.ip == ip && token == "" && key == "") {                 //disconnect
                            console.log("delete disconnect", model.body)
                            if(subjectsList.has(model.token)) subjectsList.delete(model.token)
                                dataDownloadModel.remove(model.index)
                        }
                        else {
                            if(modelType == downl) {
                                console.log("onRemoveDownloadModel", ip, token, key, subjectsList.size)
                                if(model.ip == ip && model.token == token && key != "") {   //delete file
                                    if(model.type == "files") {
                                        model.selectedCount--
                                        delete subjectsList.get(model.token)[key]
                                        if(!Object.keys(subjectsList.get(model.token)).length) {
        console.log("delete group of files because of its empty", model.index)
                                            subjectsList.delete(model.token)
                                            dataDownloadModel.remove(model.index)
                                        }
                                    }
                                    else {
                                        if(model.key == key) {
                                            dataDownloadModel.remove(model.index)
                                        }
                                    }
                                }
                                else if(model.ip == ip && model.token == token && key == "") {   //delete files
        console.log("delete files")
                                    rejectFile(model.ip, model.token, model.key)
                                    if(subjectsList.has(model.token)) subjectsList.delete(model.token)
                                    dataDownloadModel.remove(model.index)
                                }
                            }
                        }
                    }
                    function onRemoveSelection(modelType, index) {
                        if(modelType == downl) {
                            if(model.index != index) {
                                if(model.type == "files") {
                                    model.selected = false
                                    itemDelegateDownload.color = Qt.darker(colorPage, 1.2)
                                    if(model.token == dataDownloadModel.get(0).token) {
                                        finishedList.forEach(item => {
                                                                item.selected = false
                                                             })
                                    }
                                    else selectSubjects(false, model.token)
                                }
                                else if(model.type == "text") {
                                    model.selected = false
                                    itemDelegateDownload.color = Qt.darker(colorPage, 1.2)
                                }
                                else {
                                    model.selected = false
                                    if(subjectsList.has(model.token))
                                        subjectsList.get(model.token)[model.key].selected = false
                                    itemDelegateDownload.color = Qt.darker(colorPage, 1.2)
                                }
                            }
                        }
                    }
                    function onAcceptMessage(msg) {
                        if(model.selected) {
                            console.log("delete accept msg", model.index)
                            dataDownloadModel.remove(model.index)
                        }
                    }

                    function onStartOperationFile(download, token, key) {
                        if(download && model.token == token) {
                            if(model.type == "files") {
                                if(!model.process) {
                                    console.log("run mode files start")
                                    model.process = true
                                    if(!model.ungrouped) processIndicatorD.state = "show"
                                }
                                let subjects = subjectsList.get(model.token)[key]
                                if(!subjects.process) {
                                    subjects.startTime = new Date().toString()
                                    subjects.process = true
                                    model.processCount++
console.log("start 1", subjects.body)
                                }
                            }
                            else {
                                if(model.key == key) {
                                    model.startTime = new Date().toString()
                                    model.process = true
console.log("start 2", model.body)
                                }
                            }
                        }
                    }
                    function onChangedProgressFile(download, token, key, progressStatus) {
                        if(download && model.token == token) {
                            if(model.type == "files" && !model.ungrouped) {
                                if(progressStatus == -1) {
                                    model.processCount--;
                                    model.process = (model.processCount != 0)
                                    if(!model.process) processIndicatorD.state = "hide"

                                    subjectsList.get(model.token)[key].startTime = ""
                                    subjectsList.get(model.token)[key].process = false
                                    subjectsList.get(model.token)[key].indicatorStatus = 0
                                } else
                                    subjectsList.get(model.token)[key].indicatorStatus = progressStatus
                            }
                            else {
                                if(model.key == key) {
                                    if(progressStatus == -1) {
                                        timeLabelD.text = model.size
                                        model.startTime = ""
                                        model.process = false
                                        model.indicatorStatus = 0
                                    } else
                                        model.indicatorStatus = progressStatus
//console.log("change 2", model.body)
                                }
                            }
                        }
                    }
                    function onEndDownloadFile(token, key, finishedTime, filePath) {
                        if(model.token == token) {
                            removeModel(model.ip, token, key, "")
                            if(model.type == "files") {
                                let subjects = subjectsList.get(model.token)[key]
                                let item = {selected: false, startTime: finishedTime, ip: filePath, user: model.user, type: subjects.type, body: subjects.body, size: subjects.size, key: key}
                                finishedList.push(item)
                                dataDownloadModel.get(0).size = finishedList.length.toString()
                                if(dataDownloadModel.get(0).ungrouped) {
                                    item["token"] = dataDownloadModel.get(0).token
                                    dataDownloadModel.insert(finishedList.length.toString(), item)
                                }
console.log("end 1", subjects.body)
                                model.processCount--;
                                delete subjectsList.get(model.token)[key]
                                model.process = (model.processCount != 0)
                                if(!model.process) processIndicatorD.state = "hide"
//console.log(finishedList.length.toString(), JSON.stringify(finishedList))
                                if(!Object.keys(subjectsList.get(model.token)).length) {
                                    subjectsList.delete(model.token)
                                    dataDownloadModel.remove(model.index)
                                }
                            }
                            else {
                                if(model.key == key) {
                                    if(!subjectsList.has(model.token) && finishedList.findIndex(i => i.key == model.key) == -1) {
                                        let item = {selected: false, startTime: finishedTime, ip: filePath, user: model.user, type: model.type, body: model.body, size: model.size, key: key}
                                        finishedList.push(item)
                                        dataDownloadModel.get(0).size = finishedList.length.toString()
                                        if(dataDownloadModel.get(0).ungrouped) {
                                            item["token"] = dataDownloadModel.get(0).token
                                            dataDownloadModel.insert(finishedList.length.toString(), item)
                                        }
                                    }
                                    console.log("end 2", model.body)
                                    dataDownloadModel.remove(model.index)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    property int indicatorWidth: itemDelegateDownload.width / 100 * model.indicatorStatus
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    color: colorIndicateProcess
                    opacity: 0.4
                    radius: parent.radius
                    height: parent.height
                    width: indicatorStatus == 100 && !animIndicator.running ? parent.width : indicatorWidth

                    Behavior on indicatorWidth {
                        NumberAnimation {
                            id: animIndicator
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                Rectangle {
                    id: processIndicatorD
                    visible: true
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: 0.0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 1.0
                            color: itemDelegateDownload.color
                        }
                        GradientStop {
                            id: gradD
                            position: 0.0
                            color: "#bdffb3"
                        }
                        GradientStop {
                            position: 0.0
                            color: itemDelegateDownload.color
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }
                    states: [
                        State {
                            name: "show"
                            PropertyChanges {
                                target: processIndicatorD
                                opacity: 0.3
                            }
                        },
                        State {
                            name: "hide"
                            PropertyChanges {
                                target: processIndicatorD
                                opacity: 0.0
                            }
                        }
                    ]

                    NumberAnimation {
                        duration: 2000
                        running: model.process && !model.ungrouped && model.type == "files"
                        property: "position"
                        target: gradD
                        from: 0.0
                        to: 1.0
                        easing.type: Easing.InOutQuad
                        onFinished: {
                            let temp = to
                            to = from
                            from = temp
                            running = true
                        }
                    }
                }

                Timer {
                    interval: 1
                    running: model.process && model.type != "files"
                    repeat: true
                    onTriggered: timeLabelD.text = Qt.formatDateTime(new Date(new Date() - new Date(model.startTime)), "mm:ss.zzz");
                }

                MouseArea {
                    enabled: parent.enabled
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                                   if(mouse.button == Qt.LeftButton) {
                                       if((selectedList[0] == "text" && model.type != "text") ||
                                          (selectedList[0] == dataDownloadModel.get(0).token && model.token != dataDownloadModel.get(0).token) ||
                                          (selectedList[0] == btnMode.stop) ||
                                          (model.process && model.token != dataUploadModel.get(0).token)) {
                                           console.log("clear SELECTION")
                                           removeSelection(downl, model.index)
                                           selectedList = []
                                       }
                                       if(model.type == "files") {
                                           if(!model.selected) {
                                               console.log("selected group (1) " + model.index)
                                               if(model.token == dataDownloadModel.get(0).token) {
                                                   if(finishedList.length) selectEntry(btnMode.clear)
                                               }
                                               else {
                                                   if(Object.keys(subjectsList.get(model.token)).length - model.processCount)
                                                        selectEntry(btnMode.file)
                                               }
                                           }
                                           else {
                                               console.log("unselected group (1) " + model.index)
                                               if(model.token == dataDownloadModel.get(0).token) {
                                                    selectedList = []
                                               }
                                               else {
                                                   let entryId = selectedList.findIndex(i => i.token == model.token)
                                                   while(entryId != -1) {
                                                       selectedList.splice(entryId, 1)
                                                       entryId = selectedList.findIndex(i => i.token == model.token)
                                                   }
                                                }
                                           }
                                           selectSubjects(!model.selected, model.token)
                                       }
                                       else if(model.type == "text") {
                                           if(!model.selected && selectedList.length) removeSelection(downl, model.index)
                                           if(!model.selected) {
                                               console.log("selected msg (1) " + model.index)
                                               selectEntry(btnMode.text)
                                               itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.4)
                                               selectedList = ["text", model.body]
                                           }
                                           else {
                                               console.log("unselected msg (1) " + model.index)
                                               itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.2)
                                               selectedList = []
                                           }
                                       }
                                       else {
                                           if(!model.selected) {
                                               console.log("selected file (1) " + model.index, model.process, model.startTime.length)
                                               if(model.process) {
                                                   if(model.token == dataDownloadModel.get(0).token)
                                                       selectEntry(btnMode.finished)
                                                   else {
                                                       selectedList = [btnMode.stop]
                                                       selectEntry(btnMode.stop)
                                                   }
                                               }
                                               else selectEntry(btnMode.file)
                                               itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.4)
                                               if(model.token == dataDownloadModel.get(0).token) {
                                                   removeSelection(downl, model.index)
                                                   selectedList = [dataDownloadModel.get(0).token, model.key, model.ip]
                                               }
                                               else selectedList.push({ip: model.ip, token: model.token, key: model.key, name: model.body+"."+model.type, realSize: model.realSize})
                                           }
                                           else {
                                                console.log("unselected file (1) " + model.index)
                                                if(selectedList[0] == dataDownloadModel.get(0).token) {
                                                    if(!dataDownloadModel.get(0).selected) {
                                                        console.log("e1")
                                                        itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.2)
                                                        selectedList = []
                                                    }
                                                    else {
                                                        console.log("e2")
                                                        removeSelection(downl, -1)
                                                        selectEntry(btnMode.finished)
                                                        itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.4)
                                                        selectedList = [dataDownloadModel.get(0).token, model.key, model.ip]
                                                    }
                                                }
                                                else {
                                                   console.log("e3")
                                                   itemDelegateDownload.color = Qt.darker(colorSwitchLayout, 1.2)
                                                   let entryId = selectedList.findIndex(i => i.token == model.token && i.key == model.key)
                                                   selectedList.splice(entryId, 1)
                                                }
                                           }
                                           if(model.token != dataDownloadModel.get(0).token) {
                                               if(selectedList[0] != btnMode.stop) setSelectSubject(!model.selected, model.token)
                                               if(subjectsList.has(model.token))
                                                   subjectsList.get(model.token)[model.key].selected = !model.selected
                                           }
                                       }

                                       console.log("current size", selectedList.length)
                                       if(model.token == dataDownloadModel.get(0).token) {
                                           if(finishedList.length) {
                                               model.selected = !model.selected
//                                               let entryId = finishedList.findIndex(i => i.key == model.key && i.user == model.user)
//                                               if(entryId != -1) finishedList[entryId].selected = model.selected
                                           }
                                       }
                                       else {
                                           if(model.type != "files")
                                                model.selected = !model.selected
                                           else {
                                               if(model.type == "files") {
                                                   if(Object.keys(subjectsList.get(model.token)).length - model.processCount)
                                                        model.selected = !model.selected
                                               }
                                           }
                                       }
                                       if(!selectedList.length) clearEntry()
                                   }
                               }
                    onDoubleClicked: (mouse) => {
                        if(mouse.button == Qt.RightButton) {
                            if(model.type == "files") {
                                if(model.token == dataDownloadModel.get(0).token) {
                                    console.log("deleted finished files (1) " + model.index)
                                    if(model.ungrouped) ungroupSubjects(false, model.token)
                                    model.size = "0"
                                    finishedList = []
                                }
                                else {
                                    if(!model.process) {
                                        console.log("deleted data files (1) " + model.index)
                                        removeModel(model.ip, model.token, "", downl);
                                    }
                                }
                            }
                            else if(model.type == "text") {
                                console.log("deleted text (1) " + model.index)
                                dataDownloadModel.remove(model.index)
                            }
                            else {
                                if(model.token == dataDownloadModel.get(0).token) {
                                    console.log("deleted finished file (1) " + model.index)
                                    removeFinishedEntry(model.key, downl)
                                }
                                else {
                                    console.log("deleted data file (1) " + model.index)
                                    rejectFile(model.ip, model.token, model.key);
                                    removeModel(model.ip, model.token, model.key, downl);
                                }
                            }
                            removeSelection(downl, -1)
                            clearEntry()
                            selectedList = []
                         }
                    }

                    onContainsMouseChanged: {
                        if(containsMouse) {
                            itemDelegateDownload.color = model.selected ? colorSwitchLayout : Qt.darker(colorSwitchLayout, 1.2)
                        }
                        else {
                            itemDelegateDownload.color = model.selected ? Qt.darker(colorSwitchLayout, 1.4) : Qt.darker(colorPage, 1.2)
                        }
                    }
                }
                Row {
                    anchors.fill: parent
                    Item {
                        height: parent.height
                        width: parent.width / denom_DP * sizeDirect_DP - 1
                        Label {
                            anchors.centerIn: parent
                            text: model.user
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: parent.width / denom_DP * sizeType_DP - 1
                        Label {
                            anchors.centerIn: parent
                            text: model.type
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: parent.width / denom_DP * sizeName_DP - 1
                        TextInput {
                            anchors.centerIn: parent
                            text: (model.type == "files" && model.index != 0) ? qsTr("Всего: %1 -- Выбрано: %2").arg(Object.keys(subjectsList.get(model.token)).length - model.processCount).arg(model.selectedCount) : model.body
                            maximumLength: 30
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                            readOnly: true
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: (model.token == "finished" && model.type != "files") ? parent.width / denom_DP * (sizeSize_DP + sizeMode_DP) / 2 : parent.width / denom_DP * sizeSize_DP - 1
                        Label {
                            id: timeLabelD
                            anchors.centerIn: parent
                            text: model.size
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                            Component.onCompleted: {
                                if(model.startTime.length && !model.process && model.token != "finished") text = model.startTime
                                else text = model.size
                            }
                        }
                    }
                    Rectangle {
                        radius: width / 2
                        width: 1
                        height: parent.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        height: parent.height
                        width: (model.token == "finished" && model.type != "files") ? parent.width / denom_DP * (sizeSize_DP + sizeMode_DP) / 2 : parent.width / denom_DP * sizeMode_DP
                        Label {
                            visible: model.startTime.length != 0
                            anchors.centerIn: parent
                            font.pixelSize: 14
                            font.bold: true
                            text: (model.token == "finished") ? model.startTime : qsTr("%1%").arg(indicatorStatus)
                            color: "white"
                        }
                        Item {
                            visible: (model.type == "files")
                            anchors.centerIn: parent
                            height: parent.height - 2
                            width: height

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.height / 2
                                color: mouseAreaUngroupD.containsMouse ? "#15DCDCDC" : "transparent"
                            }

                            Rectangle {
                                id: moreFilesButtonD
                                anchors.centerIn: parent
                                height: mouseAreaUngroupD.containsPress ? parent.height - 2 * 6 : parent.height - 2 * 7
                                width: 3
                                radius: height / 2
                                color: mouseAreaUngroupD.containsPress ? Qt.darker("white", 1.2) : "white"
                                Behavior on rotation {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                height: 3
                                width: mouseAreaUngroupD.containsPress ? parent.height - 2 * 6 : parent.height - 2 * 7
                                radius: height / 2
                                color: mouseAreaUngroupD.containsPress ? Qt.darker("white", 1.2) : "white"
                            }

                            MouseArea {
                                id: mouseAreaUngroupD
                                property bool state: true
                                anchors.fill: parent
                                enabled: parent.enabled
                                hoverEnabled: true
                                onClicked: {
                                    if(moreFilesButtonD.rotation % 90 == 0) {
                                        if(model.token == dataDownloadModel.get(0).token && !finishedList.length) {
                                            moreFilesButtonD.rotation -= 180
                                            return;
                                        }
                                        ungroupSubjects(state, model.token)
                                        if(g_EventDataButton == btnMode.finished && safeFinishedOperate) {
                                            clearEntry()
                                            removeSelection(downl, -1)
                                            selectedList = []
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


