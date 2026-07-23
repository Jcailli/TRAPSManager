import QtQuick 2.10
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.1

Window {
    id: deviceManagerWindow
    title: "Appareils Traps App — TRAPSManager"
    width: 900
    height: 700
    minimumWidth: 640
    minimumHeight: 480
    visible: false
    flags: Qt.Window
    // Fenêtre OS indépendante (pas transiente de la fenêtre principale)
    modality: Qt.NonModal

    Material.theme: Material.Light

    function openWindow() {
        // Couper le lien transient si la propriété existe (Qt >= 5.13)
        if (typeof transientParent !== "undefined")
            transientParent = null
        visible = true
        raise()
        requestActivate()
    }

    onClosing: {
        // Garder l'instance ; seule la visibilité change
        close.accepted = false
        visible = false
    }

    DeviceManagerPanel {
        anchors.fill: parent
        fontSize: viewcontroller.fontSize
    }
}
