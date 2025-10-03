import QtQuick 2.7
import QtQuick.Controls 2.3

FocusScope {
    id: comPanel
    height: 200
    focus: true

    property bool opened: false
    property int fontSize: 18
    property bool isKayakCrossMode: viewcontroller.competitionMode === 2

    signal toggleOpenShut
    signal openRequested
    signal tabPressed
    signal animationDone
    
    onIsKayakCrossModeChanged: {
        headerModel.updateKayakCrossVisibility()
    }

    ListModel {
        id: headerModel
        ListElement { name:"CompetFFCK"; image:""; imageSelected:"" }
        ListElement { name:"Kayak Cross"; image:""; imageSelected:"" }
        
        Component.onCompleted: {
            updateKayakCrossVisibility()
        }
        
        function updateKayakCrossVisibility() {
            var isKayakCrossMode = viewcontroller.competitionMode === 2
            if (isKayakCrossMode) {
                // Afficher l'onglet Kayak Cross
                if (count === 1) {
                    append({ name:"Kayak Cross", image:"", imageSelected:"" })
                }
            } else {
                // Masquer l'onglet Kayak Cross
                if (count === 2) {
                    remove(1)
                    // Revenir à l'onglet CompetFFCK si on était sur Kayak Cross
                    if (comTitle.currentIndex === 1) {
                        comTitle.currentIndex = 0
                        displayPanel(0)
                    }
                }
            }
        }

        function showChain(index) {
            headerModel.setProperty(index, "image", "qrc:/qml/images/link_black.svg")
            headerModel.setProperty(index, "imageSelected", "qrc:/qml/images/link_white.svg")
        }
        function hideChain(index) {
            headerModel.setProperty(index, "image", "")
            headerModel.setProperty(index, "imageSelected", "")
        }

    }

    Rectangle {
        id: comPanelBg
        color: "white"
        anchors.fill: parent
    }

    TabHeader {
        id: comTitle
        height: comPanel.fontSize*2
        fontSize: comPanel.fontSize
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        cornerButtonText: comPanel.opened ? "\u25BC" : "\u25B2"
        model: headerModel
        onClick: {
            if (buttonIndex==-1 || buttonIndex==comTitle.currentIndex) {
                comPanel.toggleOpenShut()
            }
            else {
                comPanel.openRequested()
            }
            displayPanel(buttonIndex)

        }
    }


    CompetFFCKPanel {
        id: competFFCKPanel
        anchors.top: comTitle.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        fontSize: comPanel.fontSize*0.9
        onTabPressed: comPanel.tabPressed()
        onConnectedChanged: {
            if (competFFCKPanel.connected) headerModel.showChain(0)
            else headerModel.hideChain(0)
        }
    }

    // Panneau de configuration Kayak Cross
    Rectangle {
        id: kayakCrossPanel
        anchors.top: comTitle.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: "#f5f5f5"
        visible: false
        
        // Contenu du panneau Kayak Cross
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            
            // Titre
            Text {
                text: "Configuration Kayak Cross Time Trial"
                font.pixelSize: comPanel.fontSize
                font.bold: true
                color: "#333333"
            }
            
            // Sélection du nombre de postes
            Row {
                spacing: 10
                anchors.left: parent.left
                anchors.right: parent.right
                
                Text {
                    text: "Nombre de postes :"
                    font.pixelSize: comPanel.fontSize * 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                ComboBox {
                    id: postCountCombo
                    model: ["4", "5", "6", "7", "8", "9"]
                    currentIndex: Math.max(0, Math.min(5, viewcontroller.kayakCrossPostCount - 4))
                    font.pixelSize: comPanel.fontSize * 0.8
                    width: 80
                    
                    onCurrentTextChanged: {
                        var count = parseInt(currentText)
                        viewcontroller.setKayakCrossPostCount(count)
                        // Réinitialiser les types de postes
                        resetPostTypes()
                    }
                    
                    Component.onCompleted: {
                        // S'assurer que l'index est correct au chargement
                        currentIndex = Math.max(0, Math.min(5, viewcontroller.kayakCrossPostCount - 4))
                    }
                }
            }
            
            // Configuration des postes par clic
            Rectangle {
                width: parent.width
                height: 60
                color: "white"
                border.color: "#cccccc"
                border.width: 1
                radius: 4
                
                Text {
                    text: "Cliquez sur chaque poste pour changer son type :"
                    font.pixelSize: comPanel.fontSize * 0.7
                    color: "#666666"
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 5
                }
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    spacing: 5
                    
                    Repeater {
                        id: postRepeater
                        model: Math.max(4, viewcontroller.kayakCrossPostCount)
                        
                        Rectangle {
                            id: postRect
                            width: 40
                            height: 30
                            border.color: "#333333"
                            border.width: 2
                            radius: 4
                            
                            property string postType: "vide"
                            
                            color: {
                                if (postType === "descendue") return "#4CAF50"  // Vert
                                if (postType === "remontee") return "#F44336"   // Rouge
                                if (postType === "esquimautage") return "#FFC107" // Jaune
                                return "#E0E0E0"  // Gris
                            }
                            
                            Text {
                                text: {
                                    if (postRect.postType === "descendue") return "↓" + (index + 1)
                                    if (postRect.postType === "remontee") return "↑" + (index + 1)
                                    if (postRect.postType === "esquimautage") return "E"
                                    return (index + 1).toString()
                                }
                                font.pixelSize: 12
                                font.bold: true
                                color: postRect.postType === "esquimautage" ? "black" : "white"
                                anchors.centerIn: parent
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Cycle: vide -> descendue -> remontee -> esquimautage -> vide
                                    if (postRect.postType === "vide") {
                                        postRect.postType = "descendue"
                                    } else if (postRect.postType === "descendue") {
                                        postRect.postType = "remontee"
                                    } else if (postRect.postType === "remontee") {
                                        postRect.postType = "esquimautage"
                                    } else {
                                        postRect.postType = "vide"
                                    }
                                    updateConfiguration()
                                }
                                
                                ToolTip {
                                    text: {
                                        if (postRect.postType === "descendue") return "Porte descendue (cliquez pour changer)"
                                        if (postRect.postType === "remontee") return "Porte remontée (cliquez pour changer)"
                                        if (postRect.postType === "esquimautage") return "Esquimautage (cliquez pour changer)"
                                        return "Poste " + (index + 1) + " (cliquez pour configurer)"
                                    }
                                    visible: parent.containsMouse
                                }
                            }
                        }
                    }
                }
            }
            
            // Légende
            Rectangle {
                width: parent.width
                height: 40
                color: "#f8f8f8"
                border.color: "#cccccc"
                border.width: 1
                radius: 4
                
                Row {
                    anchors.centerIn: parent
                    spacing: 20
                    
                    Row {
                        spacing: 5
                        Rectangle {
                            width: 20
                            height: 15
                            color: "#4CAF50"
                            border.color: "#333333"
                            border.width: 1
                        }
                        Text {
                            text: "Porte descendue"
                            font.pixelSize: comPanel.fontSize * 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    Row {
                        spacing: 5
                        Rectangle {
                            width: 20
                            height: 15
                            color: "#F44336"
                            border.color: "#333333"
                            border.width: 1
                        }
                        Text {
                            text: "Porte remontée"
                            font.pixelSize: comPanel.fontSize * 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    Row {
                        spacing: 5
                        Rectangle {
                            width: 20
                            height: 15
                            color: "#FFC107"
                            border.color: "#333333"
                            border.width: 1
                        }
                        Text {
                            text: "Esquimautage"
                            font.pixelSize: comPanel.fontSize * 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
            
            // Bouton de validation
            Button {
                text: "Valider la configuration"
                font.pixelSize: comPanel.fontSize * 0.8
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: validateConfiguration()
                
                onClicked: {
                    applyConfiguration()
                }
            }
            
            // Message de validation
            Text {
                id: validationMessage
                font.pixelSize: comPanel.fontSize * 0.7
                color: validateConfiguration() ? "#4CAF50" : "#F44336"
                anchors.horizontalCenter: parent.horizontalCenter
                text: getValidationMessage()
            }
        }
    }


    Behavior on y {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function displayPanel(buttonIndex) {
        // Masquer tous les panneaux
        competFFCKPanel.visible = false
        kayakCrossPanel.visible = false
        
        if (buttonIndex===0) {
            competFFCKPanel.visible = true
        }
        else if (buttonIndex===1 && isKayakCrossMode) {
            kayakCrossPanel.visible = true
            // Initialiser la configuration à partir des données existantes
            initializeFromCurrentConfig()
        }
        else if (buttonIndex===1 && !isKayakCrossMode) {
            // Si on essaie d'accéder à Kayak Cross mais que ce n'est pas le bon mode,
            // revenir à CompetFFCK
            competFFCKPanel.visible = true
            comTitle.currentIndex = 0
        }
    }
    
    // Fonctions pour la configuration Kayak Cross
    function resetPostTypes() {
        for (var i = 0; i < postRepeater.count; i++) {
            var post = postRepeater.itemAt(i)
            if (post) {
                post.postType = "vide"
            }
        }
    }
    
    function initializeFromCurrentConfig() {
        // Mettre à jour le ComboBox avec le nombre de postes actuel
        postCountCombo.currentIndex = Math.max(0, Math.min(5, viewcontroller.kayakCrossPostCount - 4))
        
        // Initialiser la configuration à partir des données existantes
        if (viewcontroller.kayakCrossPostTypes && viewcontroller.kayakCrossPostTypes.length > 0) {
            for (var i = 0; i < Math.min(postRepeater.count, viewcontroller.kayakCrossPostTypes.length); i++) {
                var post = postRepeater.itemAt(i)
                if (post) {
                    var postType = viewcontroller.kayakCrossPostTypes[i]
                    if (postType === "Porte descendue") {
                        post.postType = "descendue"
                    } else if (postType === "Porte remontée") {
                        post.postType = "remontee"
                    } else if (postType === "Esquimautage") {
                        post.postType = "esquimautage"
                    } else {
                        post.postType = "vide"
                    }
                }
            }
        } else {
            resetPostTypes()
        }
    }
    
    function updateConfiguration() {
        // Cette fonction est appelée à chaque changement de poste
        // Elle peut être utilisée pour des mises à jour en temps réel si nécessaire
    }
    
    function validateConfiguration() {
        var descendues = 0
        var remontees = 0
        var esquimautage = 0
        
        for (var i = 0; i < postRepeater.count; i++) {
            var post = postRepeater.itemAt(i)
            if (post) {
                if (post.postType === "descendue") descendues++
                else if (post.postType === "remontee") remontees++
                else if (post.postType === "esquimautage") esquimautage++
            }
        }
        
        // Validation des contraintes réelles
        return descendues >= 4 && descendues <= 6 && 
               remontees >= 0 && remontees <= 2 && 
               esquimautage >= 0 && esquimautage <= 1
    }
    
    function getValidationMessage() {
        var descendues = 0
        var remontees = 0
        var esquimautage = 0
        
        for (var i = 0; i < postRepeater.count; i++) {
            var post = postRepeater.itemAt(i)
            if (post) {
                if (post.postType === "descendue") descendues++
                else if (post.postType === "remontee") remontees++
                else if (post.postType === "esquimautage") esquimautage++
            }
        }
        
        if (descendues < 4) return "❌ Il faut au moins 4 portes descendues"
        if (descendues > 6) return "❌ Il ne peut y avoir que 6 portes descendues maximum"
        if (remontees > 2) return "❌ Il ne peut y avoir que 2 portes remontées maximum"
        if (esquimautage > 1) return "❌ Il ne peut y avoir qu'1 seul esquimautage maximum"
        
        var esquimautageText = esquimautage === 0 ? "aucun" : "1"
        return "✅ Configuration valide : " + descendues + " descendues, " + remontees + " remontées, " + esquimautageText + " esquimautage"
    }
    
    function applyConfiguration() {
        var postTypes = []
        
        for (var i = 0; i < postRepeater.count; i++) {
            var post = postRepeater.itemAt(i)
            if (post && post.postType !== "vide") {
                if (post.postType === "descendue") postTypes.push("Porte descendue")
                else if (post.postType === "remontee") postTypes.push("Porte remontée")
                else if (post.postType === "esquimautage") postTypes.push("Esquimautage")
            }
        }
        
        viewcontroller.setKayakCrossPostTypes(postTypes)
        
        // Message de succès
        var descendues = 0
        var remontees = 0
        var esquimautage = 0
        
        for (var i = 0; i < postRepeater.count; i++) {
            var post = postRepeater.itemAt(i)
            if (post) {
                if (post.postType === "descendue") descendues++
                else if (post.postType === "remontee") remontees++
                else if (post.postType === "esquimautage") esquimautage++
            }
        }
        
        var message = "✅ Configuration Kayak Cross appliquée : " + descendues + " descendues, " + remontees + " remontées"
        if (esquimautage > 0) message += ", " + esquimautage + " esquimautage"
        viewcontroller.toast(message, 3000)
    }


}



