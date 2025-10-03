import QtQuick 2.7

Item {

    id: penaltyHeader

    property int fontSize: 18
    property bool isPatrolMode: viewcontroller.competitionMode === 1
    property bool isKayakCrossMode: viewcontroller.competitionMode === 2

    height: fontSize*1.5

    Rectangle {
        color: "black"
        anchors.fill: parent
    }
    Row {
        height: penaltyHeader.height
        spacing: 1
        Repeater {
            model: isPatrolMode ? viewcontroller.gateCount * 3 : (isKayakCrossMode ? viewcontroller.kayakCrossPostCount + 2 : viewcontroller.gateCount)
            Rectangle {
                width: fontSize*3-1
                height: penaltyHeader.height
                color: {
                    if (isKayakCrossMode) {
                        // Couleurs selon la configuration Kayak Cross
                        if (index === 0) {
                            return "#2196F3"  // Bleu pour Départ
                        } else if (index === viewcontroller.kayakCrossPostCount + 1) {
                            return "#2196F3"  // Bleu pour Arrivée
                        } else {
                            // Couleur selon le type de poste
                            var postIndex = index - 1
                            if (postIndex < viewcontroller.kayakCrossPostTypes.length) {
                                var postType = viewcontroller.kayakCrossPostTypes[postIndex]
                                if (postType === "Porte descendue") return "#4CAF50"  // Vert
                                if (postType === "Porte remontée") return "#F44336"   // Rouge
                                if (postType === "Esquimautage") return "#FFC107"     // Jaune
                            }
                            return "#E0E0E0"  // Gris par défaut
                        }
                    } else {
                        return "gray"  // Couleur normale pour les autres modes
                    }
                }
                border.width: 1
                border.color: "white"
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: {
                        if (isKayakCrossMode && index > 0 && index <= viewcontroller.kayakCrossPostCount) {
                            var postIndex = index - 1
                            if (postIndex < viewcontroller.kayakCrossPostTypes.length) {
                                var postType = viewcontroller.kayakCrossPostTypes[postIndex]
                                if (postType === "Esquimautage") return "black"  // Texte noir sur jaune
                            }
                        }
                        return "white"  // Texte blanc par défaut
                    }
                    font.pixelSize: fontSize
                    text: {
                        if (isPatrolMode) {
                            var gateNumber = Math.floor(index / 3) + 1
                            var letter = ["A", "B", "C"][index % 3]
                            return gateNumber + letter
                        } else if (isKayakCrossMode) {
                            if (index === 0) {
                                return "D"
                            } else if (index === viewcontroller.kayakCrossPostCount + 1) {
                                return "A"
                            } else {
                                return "P" + index
                            }
                        } else {
                            return "" + (index + 1)
                        }
                    }
                }
            }
        }
    }
}

