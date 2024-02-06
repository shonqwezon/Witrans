import QtQuick 2.15
import QtQuick.Window
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import Qt.labs.platform 1.1

ApplicationWindow {
    id: window
    width: 820
    height: width * 0.58
    visible: true
    title: qsTr(Qt.application.name)

    flags: Qt.FramelessWindowHint | Qt.WA_TranslucentBackground

    color: "#00000000"

    property int fontSizeMenu: 16
    property int globalRadius: 25

    property bool blockCliks: false
    property bool blur: false
    property int openedPageMenu: 0

    property color colorHeader: "#5e588c"
    property color colorMenu: "#423c63"
    property color colorForm: "#2c2842"
    property color colorTextMenu: "white"
    property color colorloginHeader: "#22d6ca"
    property color colorStatus: "#29b365"
    property color colorButtons: "#78dbe2"
    property color colorMenuSettings: "#474389"
    property color colorMenuBorderSettings: "#c3c5e3"
    property color colorMenuTextSettings: "#c3c5e3"
    property color colorMenuAction: "white"

    property bool selectedReceivers: false
    property bool readySend: true
    property bool deleteButton: false

    property int previousX
    property int previousY

    function closeMenuSettings() {
        blockCliks = false
        animateMenuSettings.from = 1
        animateMenuSettings.to = 0
        animateMenuSettings.start()
    }

    MouseArea {
        width: parent.width
        anchors.top: header.top
        anchors.bottom: header.bottom
        onPressed: {
            previousX = mouseX
            previousY = mouseY
        }
        onMouseXChanged: {
            var dx = mouseX - previousX
            window.setX(window.x + dx);
        }
        onMouseYChanged: {
            var dy = mouseY - previousY
            window.setY(window.y + dy);
        }
    }

    SystemTrayIcon {
        visible: true
        icon.source: "qrc:/icons/icons/logoTray.png"
        tooltip: "Witrans"

        menu: Menu {
            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }

        onActivated: {
            window.show()
            window.raise()
            window.requestActivate()
        }
    }

    header: Rectangle {
        id: header
        width: parent.width
        height: 50
        color: colorHeader
        radius: globalRadius
        Rectangle {
            color: parent.color
            anchors.bottom: header.bottom
            width: parent.width
            height: parent.radius
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: parent.width / 4 - width / 2
            text: Qt.application.name
            color: "white"
            font.pixelSize: 30
            font.bold: true
        }
        Label {
            id: welcomeHeader
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: stackView.width / 2 - width / 1.5
            text: qsTr("Добро пожаловать:")
            color: "white"
            font.pixelSize: 15
        }

        Label {
            id: loginHeader
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: welcomeHeader.right
            anchors.leftMargin: 6
            color: colorloginHeader
            text: "undefinded"
            font.pixelSize: 16
            font.bold: true
            Component.onCompleted: {
                text = registry.getLogin()
            }
        }

        RoundAvatar {
            id: roundAvatar
            size: 37
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: loginHeader.right
            anchors.leftMargin: 8
            Component.onCompleted: {
                sourceImage = registry.getAvatar()
            }
        }

        TriangleButton {
            id: triangleButton
            colorButton: colorButtons
            size: 14
            anchors.top: parent.top
            anchors.topMargin: parent.height/6
            anchors.left: roundAvatar.right
            anchors.leftMargin: 9

            onTriedPress: pageSettings.checkValid()

            onIconPressedOpened: {
                blockCliks = true
                blur = true
                blurNotification.visible = true
                notification.enabled = false

                menuSettings.visible = true
                animateMenuSettings.from = 0
                animateMenuSettings.to = 1
                animateMenuSettings.start()
            }
            onIconPressedClosed: {
                switch(openedPageMenu) {
                    case 1: {
                        pageReport.fromAnimate = 1
                        pageReport.toAnimate = 0
                        pageReport.runAnimate = true
                        break;
                    }
                    case 2: {
                        animatePageSettings.open = false
                        animatePageSettings.start()
                        break;
                    }
                    case 3: {
                        pageAddDevice.fromAnimate = 1
                        pageAddDevice.toAnimate = 0
                        pageAddDevice.runAnimate = true
                        break;
                    }
                    default: {
                        closeMenuSettings();
                        break;
                    }
                }
                openedPageMenu = 0
            }
        }

        Item {
            id: minimazeAnchor
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: parent.height / 1.3
        }
        Rectangle {
            id: minimazeItem
            anchors.centerIn: minimazeAnchor
            height: 6
            width: 25
            radius: height / 2
            color: mouseAreaMinimaze.containsMouse ? Qt.darker(colorMenuBorderSettings, 1.2) : colorMenuBorderSettings
            MouseArea {
                id: mouseAreaMinimaze
                anchors.fill: parent
                hoverEnabled: true
                onContainsMouseChanged: {
                    if(!animMinimize.running) {
                        animMinimize.start()
                    }
                }
                onClicked: {
                    window.hide()
                }
            }
            NumberAnimation {
                property bool mode: false
                id: animMinimize
                target: minimazeItem
                to: mode ? minimazeItem.width - 10 : minimazeItem.width + 10
                property: "width"
                duration: 200
                easing.type: Easing.InOutQuad
                onFinished: mode = !mode
            }
        }
    }

    MenuSettings {
        id: menuSettings
        backgroundColor: colorMenuSettings
        backgroundBorderColor: colorMenuBorderSettings
        colorText: colorMenuTextSettings
        colorIcon: colorloginHeader
        anchors.centerIn: parent
        width: 250
        height: 200
        visible: false
        z: 2
        NumberAnimation {
            target: menuSettings
            id: animateMenuSettings
            property: "opacity"
            duration: 300
            onStarted: {
                triangleButton.enabled = false
            }

            onFinished: {
                triangleButton.enabled = true
                if(!blockCliks) {
                    menuSettings.visible = false
                    blur = false
                    blurNotification.visible = false
                    notification.enabled = true
                }
            }
        }
        onOpenReport: {
            closeMenuSettings()
            openedPageMenu = 1
            pageReport.fromAnimate = 0
            pageReport.toAnimate = 1
            pageReport.runAnimate = true
        }

        onOpenSettings: {
            triangleButton.valid = false
            closeMenuSettings()
            openedPageMenu = 2
            animatePageSettings.open = true
            animatePageSettings.start()
        }

        onOpenAddDevice: {
            closeMenuSettings()
            openedPageMenu = 3
            pageAddDevice.fromAnimate = 0
            pageAddDevice.toAnimate = 1
            pageAddDevice.runAnimate = true
            guiService.clearDeviceCode();
            pageAddDevice.textId = deviceService.getCode()
        }
    }

    MenuNotifications {
        z: 2
        id: menuNotifications
        backgroundColor: colorMenuSettings
        backgroundBorderColor: colorMenuBorderSettings
        anchors.centerIn: parent
        width: 450
        height: 300
        visible: false

        onChangeStatus: (mode) => notification.notifStatus = mode
        onCloseNotif: notification.runNotification()

        NumberAnimation {
            target: menuNotifications
            id: animateMenuNotifications
            property: "opacity"
            duration: 300
            onStarted: {
                notification.enabled = false
            }

            onFinished: {
                notification.enabled = true
                if(!blockCliks) {
                    menuNotifications.visible = false
                    blur = false
                    triangleButton.enabled = true
                }
            }
        }
    }

    FastBlur {
        anchors.fill: stackView
        source: ShaderEffectSource {
            sourceItem: stackView
        }
        visible: blur
        radius: 15
        z: 1
    }
    FastBlur {
        anchors.fill: column
        source: ShaderEffectSource {
            sourceItem: column
        }
        visible: blur
        radius: 15
        z: 1
    }

    FastBlur {
        id: blurNotification
        anchors.fill: notification
        source: ShaderEffectSource {
            sourceItem: notification
        }
        radius: 15
        visible: false
        z: 1
    }

    //-------------------------------------------------------

    PageReport {
        id: pageReport
        anchors.fill: parent
        z: 3
        radiusBack: globalRadius
    }

    PageSettings {
        id: pageSettings
        anchors.fill: parent
        z: 3
        radiusBack: globalRadius
        onCheckSizeAvatar: (url) => {
            var request = guiService.checkSizeAvatar(url)
            pageSettings.setAvatar(request)
        }
        NumberAnimation {
            property bool open: true
            property string oldLogin: ""
            property string oldAvatar: ""
            property bool oldMinimized
            property bool oldAutopaste
            id: animatePageSettings
            target: pageSettings
            property: "opacity"
            duration: 300
            from: open ? 0 : 1
            to: open ? 1 : 0
            onStarted: {
                pageSettings.visible = true
            }
            onFinished: {
                if(!pageSettings.opacity) pageSettings.visible = false
                if(open) {
                    oldLogin = pageSettings.login
                    oldAvatar = pageSettings.sourceAvatar
                    oldMinimized = pageSettings.modeMinimized
                    oldAutopaste = pageSettings.modeAutopaste
                }
                else {
                    pageSettings.loginFocus = false
                    if(oldLogin != pageSettings.login) registry.setLogin(pageSettings.login)
                    if(oldAvatar != pageSettings.sourceAvatar) registry.setAvatar(pageSettings.sourceAvatar)
                    if(oldMinimized != pageSettings.modeMinimized) registry.setMinimized(pageSettings.modeMinimized)
                    if(oldMinimized != pageSettings.oldAutopaste) registry.setAutopaste(pageSettings.modeAutopaste)
                }
            }
        }
        Component.onCompleted: {
            login = registry.getLogin()
            currentVersion = updater.getCurrentVersion()
            sourceAvatar = registry.getAvatar()
            sequenceHideApp = registry.getKeyBind();
            modeMinimized = registry.getMinimized();
            modeAutopaste = registry.getAutopaste();
            pathDefault = registry.getDefaultPath();
        }
        function checkValid() {
            pageSettings.valid = true
            pageSettings.restoreValid()
            if(pageSettings.valid) {
                triangleButton.valid = true
                triangleButton.imitClick()
            }
        }
    }

    PageAddDevice {
        id: pageAddDevice
        anchors.fill: parent
        z: 3
        radiusBack: globalRadius
        onAddDevice: (code) => { deviceService.requestDevice(code) }
    }

    StackView {
        id: stackView
        initialItem: pageMain
        anchors.left: column.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
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
                NumberAnimation   {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 1
                }
          }
    }

    MenuTabMain {
        id: pageMain
        visible: true
        enabled: !blur
        colorPage: colorForm
        onDeleteDevice: (ip) => {
            deviceService.sendDeleteDevice(ip)
        }
        onRenameDevice: (ip, name) => {
            deviceService.renameDevice(ip, name)
        }
        onAddReceivers: (ip) => {
            deviceService.addReceiver(ip)
        }
        onDeleteReceivers: (ip) => {
            deviceService.removeReceiver(ip)
        }
        onClearReceivers: {
            deviceService.clearReceiver()
        }
    }

    MenuTabAdd {
        id: pageAdd
        enabled: !blur
        colorPage: colorForm
        onClearFiles: guiService.clearFiles()
        onGetCopiedData: {
            appendFiles(guiService.getCopiedData())
        }
        onAddDeleteFile: (selected, path) => {
            guiService.addDeleteFile(selected, path)
        }
        onChangedReadyState: (state) => {
            if(state) {
                readySend = true
                sendButton.iconColor = colorMenuAction
            }
            else {
                readySend = false
                sendButton.iconColor = Qt.darker(colorMenuAction, 1.8)
            }
        }
        onRenameFile: (path, newName) => {
            guiService.renameFile(path, newName);
        }
        onAddFiles: (paths) => {
            appendFiles(guiService.appendFiles(paths))
        }
    }

    MenuTabProcess {
        id: pageProcess
        enabled: !blur
        colorPage: colorForm
        colorSwitch: colorloginHeader
        colorBorder: colorStatus
        onCancelRequest: (ip, token, id) => {
            deviceService.cancelRequest(ip, token, id)
        }
        onStopFile: (download, ip, token, id) => {
            if(download) deviceService.stopDownloadFile(ip, token, id)
            else server.stopUploadFile(ip, token, id)
        }

        onAcceptFile: (ip, token, id, name, realSize) => {
            deviceService.acceptFile(ip, token, id, name, realSize)
        }
        onAcceptMessage: (msg) => {
            guiService.copyText(msg)
        }
        onRejectFile: (ip, token, id) => {
            deviceService.rejectFile(ip, token, id)
        }
        onOpenDirectory: (filePath) => {
            guiService.openDirectory(filePath)
        }
        onOpenFile: (filePath) => {
            guiService.openFile(filePath)
        }

        onOpenTab: {
            window.show()
            window.raise()
            window.requestActivate()
            if(getDataButton.click) getDataButton.pressedIcon()
        }
    }

    Notification {
        z:1
        id: notification
        anchors.bottom: column.bottom
        anchors.right: column.right
        anchors.bottomMargin: 20
        anchors.rightMargin: 20
        size: 30
        opacity: blurNotification.visible ? 0.2 : 1
        colorImage: "white"
        imageSource: "qrc:/icons/icons/notificationClosed.png"
        notifStatus: false

        onNotificationOpened: {
            triangleButton.enabled = false
            blockCliks = true
            blur = true
            menuNotifications.visible = true
            animateMenuNotifications.from = 0
            animateMenuNotifications.to = 1
            animateMenuNotifications.running = true
        }
        onNotificationClosed: {
            blockCliks = false
            animateMenuNotifications.from = 1
            animateMenuNotifications.to = 0
            animateMenuNotifications.running = true
        }
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 4
        height: parent.height

        Rectangle {
            anchors.fill: parent
            color: colorMenu
            radius: globalRadius
            Rectangle {
                color: parent.color
                anchors.top: parent.top
                width: parent.width
                height: parent.radius
            }
            Rectangle {
                color: parent.color
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                width: parent.radius
            }
        }

        MenuAction {
            id: devicesButton
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: 55

            widthIcon: 80
            heightIcon: 80
            height: 80

            Layout.fillWidth: true
            enabled: !blockCliks
            click: (stackView.currentItem != pageMain)

            icon: "qrc:/icons/icons/devices.png"
            iconColor: colorMenuAction
            onPressedIcon: {
                if(!pageMain.visible) pageMain.visible = true
                stackView.replace(pageMain)
                animateX.to = devicesButton.y
                animate.running = true

                if(selectedReceivers) {
                    readySend = true
                    sendButton.iconColor = colorMenuAction
                }
            }
        }

        MenuAction {
            id: sendButton
            Layout.alignment: Qt.AlignHCenter

            widthIcon: 80
            heightIcon: 64
            height: 64

            Layout.fillWidth: true
            enabled: !blockCliks && selectedReceivers && readySend

            icon: "qrc:/icons/icons/send.png"
            iconColor: Qt.darker(colorMenuAction, 1.8)
            onPressedIcon: {
                if(stackView.currentItem != pageAdd) {
                    if(!pageAdd.visible) pageAdd.visible = true
                    stackView.replace(pageAdd)
                    animateX.to = sendButton.y - 8
                    animate.running = true
                    if(registry.getAutopaste()) pageAdd.setDataModel(guiService.getCopiedData());
                    else pageAdd.setDataModel(["none"]);
                }
                else {
                    if(deleteButton) {
                        pageAdd.deleteFiles()
                        guiService.deleteSelectedFiles()
                        deleteButton = false
                        icon = "qrc:/icons/icons/send.png"
                    }
                    else {
                        var data = pageAdd.sendData()
                        switch(data[0]) {
                        case '0':
console.log("Send data - error")
                            break;
                        case '1':
                            devicesButton.pressedIcon()
                            deviceService.sendText(data[1]);
                            break;
                        case '2':
                            devicesButton.pressedIcon()
                            deviceService.requestFiles(guiService.getFiles());
                            break;
                        }
                        pageMain.clearReceivers() //?
                    }
                }
            }
        }

        MenuAction {
            id: getDataButton
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.bottomMargin: 70

            widthIcon: 78
            heightIcon: 78
            height: 78

            Layout.fillWidth: true
            enabled: !blockCliks

            click: (stackView.currentItem != pageProcess)
            icon: "qrc:/icons/icons/download.png"
            iconColor: colorMenuAction
            onPressedIcon: {
                if(!pageProcess.visible) pageProcess.visible = true
                stackView.replace(pageProcess)
                animateX.to = getDataButton.y
                animate.running = true

                if(selectedReceivers) {
                    readySend = true
                    sendButton.iconColor = colorMenuAction
                }
            }
        }

        Rectangle {
            z: 0
            id: statusBarReceivers
            anchors.left: parent.left
            anchors.verticalCenter: sendButton.verticalCenter
            anchors.leftMargin: 3
            width: 9
            color: (readySend && stackView.currentItem == pageAdd) ? colorStatus : "#b8b800"
            radius: 8
            ParallelAnimation {
                id: animateStatusBarReceivers

                NumberAnimation {
                    target: statusBarReceivers
                    property: "height"
                    duration: 150
                    from: selectedReceivers ? 40 : 80
                    to: selectedReceivers ? 80 : 40
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: statusBarReceivers
                    property: "opacity"
                    duration: 140
                    from: selectedReceivers ? 0 : 100
                    to: selectedReceivers ? 100 : 0
                }
            }
        }

        Item {
            z: 0
            id: statusBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 12
            height: parent.height
            Rectangle {
                id: status
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 3
                width: 9
                height: 80
                y: devicesButton.y
                color: colorStatus
                radius: 8

                ParallelAnimation {
                    id: animate

                    NumberAnimation {
                        id: animateX
                        target: status
                        property: "y"
                        from: status.y
                        duration: 160
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: status
                            property: "height"
                            from: status.height
                            to: status.height + 30
                            duration: 80
                        }
                        NumberAnimation {
                            target: status
                            property: "height"
                            from: status.height + 30
                            to: status.height
                            duration: 80
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: registry
        function onChangedLogin() {
            loginHeader.text = registry.getLogin();
        }
        function onChangedAvatar() {
            roundAvatar.sourceImage = registry.getAvatar();
        }
    }

    Connections {
        target: guiService
        function onActiveDeleteButton() {
            sendButton.icon = "qrc:/icons/icons/deleteFiles.png"
            deleteButton = true
        }
        function onDeactiveDeleteButton() {
            sendButton.icon = "qrc:/icons/icons/send.png"
            deleteButton = false
        }
    }
    Connections {
        target: deviceService
        function onDeleteIrrelevantFile(download, ip, token, key) {
            if(download) pageProcess.removeModel(ip, token, key, "downl")
            else pageProcess.removeModel(ip, token, key, "upl")
            pageProcess.removeModel(ip, token, key, "")
        }
        function onStartOperationFile(download, token, key) {
            console.log("START Operation File")
            pageProcess.startOperationFile(download, token, key)
        }
        function onChangedProgress(download, token, key, progressStatus) {
            pageProcess.changedProgressFile(download, token, key, progressStatus)
        }
        function onEndDownloadFile(token, key, finishedTime, filePath) {
            console.log("END Download File")
            pageProcess.endDownloadFile(token, key, finishedTime, filePath)
        }

        function onNewRequestData(download, type, ip, user, size, list) {
            if(download) pageProcess.appendDownloadModel(type, ip, user, size, list)
            else pageProcess.appendUploadModel(type, ip, user, size, list)
        }

        function onActivateTab() {
            selectedReceivers = true
            readySend = true
            sendButton.iconColor = colorMenuAction
            animateStatusBarReceivers.running = true
        }
        function onDeactivateTab() {
            if(stackView.currentItem == pageAdd) {
                devicesButton.pressedIcon();
            }
            selectedReceivers = false
            sendButton.iconColor = Qt.darker(colorMenuAction, 1.8)
            animateStatusBarReceivers.running = true
            pageAdd.clearDataModel();
        }
        function onConnectedNewDevice(ip, list) {
            pageMain.appendNewDevice(ip, list);
        }
        function onDisconnectedOldDevice(ip) {
            pageMain.disconectedDevice(ip);
            pageProcess.removeModel(ip, "", "", "")
        }
        function onResponseDevice(response) {
            pageAddDevice.responseAddDevice(response)
        }
        function onNewNotification(type, body, time) {
            menuNotifications.addNotification([type, body, time])
        }
    }
    Connections {
        target: server
        function onChangedCode() {
            var deviceCode = deviceService.getCode();
            pageAddDevice.textId = deviceCode;
            guiService.changeDeviceCode(deviceCode);
        }
    }
    Connections {
        target: windowsHooks
        function onKeyboardEvent() {
            if(!window.active) {
                window.show()
                window.raise()
                window.requestActivate()
                if(devicesButton.click) devicesButton.pressedIcon()
            }
            else {
                if(!pageSettings.visible)
                    window.hide()
            }
        }
    }

    Connections {
        target: updater
    }

    Component.onCompleted: {
        if(registry.getMinimized()) window.hide();
    }
}

