import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.1

Rectangle {
    id: kayakCrossPostDisplay
    
    property bool isKayakCrossMode: viewcontroller.competitionMode === 2
    property var postTypes: viewcontroller.kayakCrossPostTypes || []
    property int postCount: viewcontroller.kayakCrossPostCount
    
    visible: isKayakCrossMode
    height: isKayakCrossMode ? 60 : 0
    color: "#f0f0f0"
    border.color: "#cccccc"
    border.width: 1
    
    // Titre
    Text {
        id: titleText
        text: "Configuration Kayak Cross Time Trial"
        font.pixelSize: 16
        font.bold: true
        color: "#333333"
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 8
    }
    
    // Affichage des postes
    Row {
        id: postsRow
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.top: titleText.bottom
        anchors.topMargin: 5
        spacing: 5
        
        Repeater {
            model: postTypes
            
            Rectangle {
                width: 80
                height: 30
                color: {
                    if (modelData === "Porte descendue") return "#4CAF50"  // Vert
                    if (modelData === "Porte remontée") return "#FF9800"   // Orange
                    if (modelData === "Esquimautage") return "#2196F3"      // Bleu
                    return "#cccccc"
                }
                border.color: "#333333"
                border.width: 1
                radius: 4
                
                Text {
                    text: {
                        if (modelData === "Porte descendue") return "↓" + (index + 1)
                        if (modelData === "Porte remontée") return "↑" + (index + 1)
                        if (modelData === "Esquimautage") return "E"
                        return "?"
                    }
                    font.pixelSize: 12
                    font.bold: true
                    color: "white"
                    anchors.centerIn: parent
                }
                
                // Tooltip avec description
                ToolTip {
                    text: modelData
                    visible: mouseArea.containsMouse
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
    
    // Informations de configuration
    Text {
        id: configText
        text: {
            if (postTypes.length === 0) return "Aucune configuration"
            
            var descendues = 0
            var remontees = 0
            var esquimautage = 0
            
            for (var i = 0; i < postTypes.length; i++) {
                if (postTypes[i] === "Porte descendue") descendues++
                else if (postTypes[i] === "Porte remontée") remontees++
                else if (postTypes[i] === "Esquimautage") esquimautage++
            }
            
            return "Total: " + postCount + " postes | " + 
                   descendues + " descendues, " + 
                   remontees + " remontées, " + 
                   esquimautage + " esquimautage"
        }
        font.pixelSize: 12
        color: "#666666"
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: titleText.bottom
        anchors.topMargin: 5
    }
    
    // Bouton de configuration
    Button {
        id: configButton
        text: "Configurer"
        width: 80
        height: 30
        anchors.right: statusIndicator.left
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 10
        font.pixelSize: 12
        
        onClicked: {
            viewcontroller.openKayakCrossPostConfig()
        }
        
        ToolTip {
            text: "Ouvrir la configuration des postes"
            visible: configButton.hovered
        }
    }
    
    // Indicateur de statut
    Rectangle {
        id: statusIndicator
        width: 12
        height: 12
        radius: 6
        color: {
            if (postTypes.length === 0) return "#f44336"  // Rouge - pas de config
            if (postTypes.length < 5) return "#ff9800"    // Orange - config incomplète
            return "#4caf50"  // Vert - config valide
        }
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 10
        
        ToolTip {
            text: {
                if (postTypes.length === 0) return "Aucune configuration"
                if (postTypes.length < 5) return "Configuration incomplète"
                return "Configuration valide"
            }
            visible: statusIndicatorMouseArea.containsMouse
        }
        
        MouseArea {
            id: statusIndicatorMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
