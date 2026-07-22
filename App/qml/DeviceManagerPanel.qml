import QtQuick 2.7
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

Rectangle {
    id: deviceManagerPanel
    color: "#f5f5f5"
    property int fontSize: 18

    property var server: viewcontroller.deviceConnectionServer
    property var allowlist: server ? server.allowlist : null

    ScrollView {
        anchors.fill: parent
        anchors.margins: 10
        contentWidth: deviceManagerPanel.width - 20
        clip: true

        Column {
            width: deviceManagerPanel.width - 30
            spacing: 12

            // --- Serveur ---
            Rectangle {
                width: parent.width
                height: serverRow.height + 24
                color: "white"
                border.color: "#2196F3"
                border.width: 2
                radius: 8

                Row {
                    id: serverRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Column {
                        width: parent.width - 160
                        spacing: 4
                        Text {
                            text: "Appareils Traps App"
                            font.pixelSize: fontSize
                            font.bold: true
                            color: "#1565C0"
                        }
                        Text {
                            text: (server && server.listening)
                                  ? ("En écoute sur le port " + viewcontroller.deviceConnectionPort
                                     + " — " + (server.connectedDeviceCount || 0) + " connecté(s), "
                                     + (server.activeDeviceCount || 0) + " actif(s)")
                                  : "Serveur arrêté"
                            font.pixelSize: fontSize * 0.7
                            color: "#555"
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
                    }

                    Button {
                        text: "Port…"
                        width: 140
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: portDialog.open()
                    }
                }
            }

            // --- Sync dossards ---
            Rectangle {
                width: parent.width
                height: syncCol.height + 24
                color: "#FFF8E1"
                border.color: "#FF9800"
                border.width: 2
                radius: 8

                Column {
                    id: syncCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    spacing: 8

                    Text {
                        text: "Synchronisation dossards"
                        font.pixelSize: fontSize * 0.9
                        font.bold: true
                        color: "#E65100"
                    }
                    Text {
                        text: "Envoie la liste chargée dans TRAPSManager aux téléphones autorisés et connectés."
                        font.pixelSize: fontSize * 0.65
                        color: "#6D4C41"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    Button {
                        text: "Envoyer la liste à tous (" + viewcontroller.bibCount + " dossards)"
                        width: parent.width
                        height: 40
                        enabled: viewcontroller.bibCount > 0 && server && server.connectedDeviceCount > 0
                        onClicked: viewcontroller.broadcastBibListToDevices()
                    }
                }
            }

            // --- Allowlist ---
            Rectangle {
                width: parent.width
                height: allowCol.height + 24
                color: "white"
                border.color: "#4CAF50"
                border.width: 1
                radius: 8

                Column {
                    id: allowCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    spacing: 10

                    Text {
                        text: "Appareils autorisés (garde-fou)"
                        font.pixelSize: fontSize * 0.9
                        font.bold: true
                        color: "#2E7D32"
                    }
                    Text {
                        text: "Ajoutez la MAC (ou IP) affichée sur Traps App avant connexion. Liste vide = aucun téléphone accepté."
                        font.pixelSize: fontSize * 0.65
                        color: "#666"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 6

                        Text { text: "Nom"; font.pixelSize: fontSize * 0.7 }
                        TextField {
                            id: newName
                            Layout.fillWidth: true
                            placeholderText: "ex. Porte 5"
                            font.pixelSize: fontSize * 0.7
                        }
                        Text { text: "MAC"; font.pixelSize: fontSize * 0.7 }
                        TextField {
                            id: newMac
                            Layout.fillWidth: true
                            placeholderText: "AA:BB:CC:DD:EE:FF"
                            font.pixelSize: fontSize * 0.7
                        }
                        Text { text: "IP (opt.)"; font.pixelSize: fontSize * 0.7 }
                        TextField {
                            id: newIp
                            Layout.fillWidth: true
                            placeholderText: "192.168.1.42"
                            font.pixelSize: fontSize * 0.7
                        }
                    }

                    Button {
                        text: "Ajouter à la liste blanche"
                        width: parent.width
                        height: 36
                        enabled: newMac.text.length > 0 || newIp.text.length > 0
                        onClicked: {
                            if (allowlist && allowlist.addDevice(newName.text, newMac.text, newIp.text, "")) {
                                newName.text = ""
                                newMac.text = ""
                                newIp.text = ""
                            }
                        }
                    }

                    Repeater {
                        model: allowlist ? allowlist.devices : []
                        delegate: Rectangle {
                            width: allowCol.width
                            height: 56
                            color: modelData.enabled === false ? "#eeeeee" : "#E8F5E9"
                            radius: 6
                            border.color: "#C8E6C9"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Column {
                                    width: parent.width - 100
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: modelData.name || "Appareil"
                                        font.pixelSize: fontSize * 0.75
                                        font.bold: true
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: (modelData.mac ? ("MAC " + modelData.mac) : "")
                                              + (modelData.mac && modelData.ip ? "  ·  " : "")
                                              + (modelData.ip ? ("IP " + modelData.ip) : "")
                                        font.pixelSize: fontSize * 0.65
                                        color: "#555"
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                }

                                Button {
                                    text: "Retirer"
                                    width: 90
                                    height: 32
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: {
                                        if (allowlist)
                                            allowlist.removeDevice(modelData.entryId)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: !allowlist || allowlist.count === 0
                        text: "Aucun appareil autorisé pour le moment."
                        font.pixelSize: fontSize * 0.7
                        color: "#F44336"
                    }
                }
            }

            // --- Connectés ---
            Rectangle {
                width: parent.width
                height: connCol.height + 24
                color: "white"
                border.color: "#9E9E9E"
                border.width: 1
                radius: 8

                Column {
                    id: connCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    spacing: 8

                    Text {
                        text: "Connectés en direct"
                        font.pixelSize: fontSize * 0.9
                        font.bold: true
                        color: "#333"
                    }

                    Text {
                        visible: !server || server.connectedDeviceCount === 0
                        text: "Aucun téléphone connecté."
                        font.pixelSize: fontSize * 0.7
                        color: "#888"
                    }

                    Repeater {
                        model: server ? server.connectedDevices : []
                        delegate: Rectangle {
                            width: connCol.width
                            height: 88
                            radius: 6
                            color: "#fafafa"
                            border.color: statusBorder

                            property string statusBorder: {
                                var s = modelData.status
                                if (s === "Active") return "#4CAF50"
                                if (s === "Idle") return "#FF9800"
                                return "#F44336"
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    width: 10
                                    height: parent.height
                                    radius: 3
                                    color: statusBorder
                                }

                                Column {
                                    width: parent.width - 200
                                    spacing: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: modelData.deviceName || modelData.deviceId
                                        font.pixelSize: fontSize * 0.75
                                        font.bold: true
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: (modelData.mac ? ("MAC " + modelData.mac + "  ") : "")
                                              + "IP " + (modelData.ipAddress || "-")
                                        font.pixelSize: fontSize * 0.65
                                        color: "#555"
                                        width: parent.width
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: "Statut: " + (modelData.status || "?")
                                              + " — depuis " + Qt.formatDateTime(new Date(modelData.connectedSince), "hh:mm:ss")
                                        font.pixelSize: fontSize * 0.65
                                        color: statusBorder
                                    }
                                }

                                Column {
                                    width: 180
                                    spacing: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    Button {
                                        text: "Envoyer liste"
                                        width: parent.width
                                        height: 28
                                        enabled: modelData.isActive && viewcontroller.bibCount > 0
                                        onClicked: viewcontroller.sendBibListToDevice(modelData.deviceId)
                                    }
                                    Button {
                                        text: "Déconnecter"
                                        width: parent.width
                                        height: 28
                                        onClicked: {
                                            if (server)
                                                server.disconnectDevice(modelData.deviceId)
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

    Dialog {
        id: portDialog
        title: "Port de connexion appareils"
        modal: true
        standardButtons: Dialog.Cancel | Dialog.Ok
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 360

        Column {
            spacing: 10
            width: parent.width
            Text {
                text: "Port TCP (1024–65535)"
                font.pixelSize: fontSize * 0.8
            }
            TextField {
                id: portField
                width: parent.width
                text: viewcontroller.deviceConnectionPort.toString()
                validator: IntValidator { bottom: 1024; top: 65535 }
                inputMethodHints: Qt.ImhDigitsOnly
            }
            Text {
                text: "Le serveur redémarre après validation. Mettez à jour Traps App si besoin."
                wrapMode: Text.Wrap
                width: parent.width
                font.pixelSize: fontSize * 0.65
                color: "#666"
            }
        }

        onAccepted: {
            var p = parseInt(portField.text)
            if (p >= 1024 && p <= 65535)
                viewcontroller.setDeviceConnectionPort(p)
        }
    }
}
