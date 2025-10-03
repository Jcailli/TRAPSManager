import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3

Dialog {
    id: kayakCrossPostConfig
    
    title: "Configuration des Postes Kayak Cross Time Trial"
    width: 600
    height: 500
    modal: true
    
    property var currentConfig: []
    property int descendues: 4
    property int remontees: 0
    property int totalPosts: 5
    
    // Contraintes
    readonly property int minDescendues: 4
    readonly property int maxDescendues: 6
    readonly property int minRemontees: 0
    readonly property int maxRemontees: 2
    readonly property int esquimautageCount: 1
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 20
        
        // Instructions
        Text {
            text: "Configurez les types de postes pour le Kayak Cross Time Trial :"
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
        }
        
        // Contraintes
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: "#e3f2fd"
            border.color: "#2196f3"
            border.width: 1
            radius: 4
            
            Column {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                
                Text {
                    text: "Contraintes :"
                    font.bold: true
                    font.pixelSize: 12
                }
                Text {
                    text: "• 4-6 Portes descendues (obligatoires)"
                    font.pixelSize: 11
                }
                Text {
                    text: "• 0-2 Portes remontées (optionnelles)"
                    font.pixelSize: 11
                }
                Text {
                    text: "• 1 Esquimautage (obligatoire, toujours à la fin)"
                    font.pixelSize: 11
                }
            }
        }
        
        // Configuration des portes descendues
        GroupBox {
            title: "Portes Descendues (obligatoires)"
            Layout.fillWidth: true
            
            Row {
                spacing: 10
                
                Text {
                    text: "Nombre :"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                SpinBox {
                    id: descenduesSpinBox
                    from: minDescendues
                    to: maxDescendues
                    value: descendues
                    onValueChanged: {
                        descendues = value
                        updateTotal()
                    }
                }
                
                Text {
                    text: "(" + minDescendues + "-" + maxDescendues + ")"
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#666666"
                }
            }
        }
        
        // Configuration des portes remontées
        GroupBox {
            title: "Portes Remontées (optionnelles)"
            Layout.fillWidth: true
            
            Row {
                spacing: 10
                
                Text {
                    text: "Nombre :"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                SpinBox {
                    id: remonteesSpinBox
                    from: minRemontees
                    to: maxRemontees
                    value: remontees
                    onValueChanged: {
                        remontees = value
                        updateTotal()
                    }
                }
                
                Text {
                    text: "(" + minRemontees + "-" + maxRemontees + ")"
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#666666"
                }
            }
        }
        
        // Aperçu de la configuration
        GroupBox {
            title: "Aperçu de la Configuration"
            Layout.fillWidth: true
            
            Column {
                spacing: 10
                
                Text {
                    text: "Total des postes : " + totalPosts
                    font.bold: true
                }
                
                // Affichage visuel des postes
                Row {
                    spacing: 5
                    
                    Repeater {
                        model: currentConfig
                        
                        Rectangle {
                            width: 40
                            height: 30
                            color: {
                                if (modelData === "Porte descendue") return "#4CAF50"
                                if (modelData === "Porte remontée") return "#FF9800"
                                if (modelData === "Esquimautage") return "#2196F3"
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
                                font.pixelSize: 10
                                font.bold: true
                                color: "white"
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
                
                // Validation
                Text {
                    text: {
                        if (totalPosts < 5) return "❌ Configuration invalide : minimum 5 postes"
                        if (totalPosts > 9) return "❌ Configuration invalide : maximum 9 postes"
                        if (descendues < 4) return "❌ Configuration invalide : minimum 4 portes descendues"
                        if (descendues > 6) return "❌ Configuration invalide : maximum 6 portes descendues"
                        if (remontees > 2) return "❌ Configuration invalide : maximum 2 portes remontées"
                        return "✅ Configuration valide"
                    }
                    color: {
                        if (totalPosts < 5 || totalPosts > 9 || descendues < 4 || descendues > 6 || remontees > 2) {
                            return "#f44336"
                        }
                        return "#4caf50"
                    }
                    font.bold: true
                }
            }
        }
        
        // Boutons
        Row {
            Layout.alignment: Qt.AlignRight
            spacing: 10
            
            Button {
                text: "Annuler"
                onClicked: kayakCrossPostConfig.reject()
            }
            
            Button {
                text: "Appliquer"
                enabled: totalPosts >= 5 && totalPosts <= 9 && descendues >= 4 && descendues <= 6 && remontees <= 2
                onClicked: {
                    applyConfiguration()
                    kayakCrossPostConfig.accept()
                }
            }
        }
    }
    
    function updateTotal() {
        totalPosts = descendues + remontees + esquimautageCount
        updateConfig()
    }
    
    function updateConfig() {
        currentConfig = []
        
        // Ajouter les portes descendues
        for (var i = 0; i < descendues; i++) {
            currentConfig.push("Porte descendue")
        }
        
        // Ajouter les portes remontées
        for (var i = 0; i < remontees; i++) {
            currentConfig.push("Porte remontée")
        }
        
        // Ajouter l'esquimautage (toujours à la fin)
        currentConfig.push("Esquimautage")
    }
    
    function applyConfiguration() {
        // Appliquer la configuration via ViewController
        // Cette fonction sera connectée au ViewController
        console.log("Configuration appliquée :", currentConfig)
    }
    
    Component.onCompleted: {
        updateConfig()
    }
}
