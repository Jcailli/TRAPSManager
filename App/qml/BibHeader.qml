import QtQuick 2.7

Rectangle {

    id: bibHeader

    property bool displayTimeData: false
    property int fontSize: 18
    property color bgcolor: "gray"
    property bool isPatrolMode: viewcontroller.competitionMode === 1

    height: fontSize*1.5

    width: {
        if (isPatrolMode && displayTimeData) {
            return fontSize*46.5+8 // Plus large pour les colonnes patrouille (8 colonnes fixes)
        } else if (displayTimeData) {
            return fontSize*21.5+6
        } else {
            return fontSize*12.5+3
        }
    }
    color: "white"

    Row {
        id: bibRow
        height: parent.height
        anchors.left: parent.left
        anchors.top:parent.top
        spacing: 1

        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*3.5
            border.width: 1
            border.color: "white"
            Text {
                id: bibIdText
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Dossard"

            }
        }
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*4
            border.width: 1
            border.color: "white"
            Text {
                id: categText
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Catégorie"
            }
        }
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*6
            border.width: 1
            border.color: "white"
            Text {
                id: scheduleText
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Horaire"
            }
        }
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*7.5
            visible: displayTimeData
            border.width: 1
            border.color: "white"
            Text {
                id: startTimeText
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Départ"
            }
        }
        // Colonnes spécifiques au mode patrouille - Arrivée1er
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*7.5
            visible: displayTimeData && isPatrolMode
            border.width: 1
            border.color: "white"
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Arrivée 1er"
            }
        }
        // Colonnes spécifiques au mode patrouille - Arrivée3ème
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*7.5
            visible: displayTimeData && isPatrolMode
            border.width: 1
            border.color: "white"
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Arrivée 3ème"
            }
        }
        // Colonnes spécifiques au mode patrouille - Écart (optionnel)
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*4
            visible: displayTimeData && isPatrolMode
            border.width: 1
            border.color: "white"
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Écart"
            }
        }
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*7.5
            visible: displayTimeData && !isPatrolMode
            border.width: 1
            border.color: "white"
            Text {
                id: finishTimeText
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Arrivée"
            }
        }
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*7.5
            visible: displayTimeData && !isPatrolMode
            border.width: 1
            border.color: "white"
            Text {
                id: elapsedTimeText
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Chrono"
            }
        }
        // Colonne Chrono pour le mode patrouille (après Écart)
        Rectangle {
            color: bgcolor
            height: parent.height
            width: fontSize*7.5
            visible: displayTimeData && isPatrolMode
            border.width: 1
            border.color: "white"
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: fontSize*0.7
                text: "Chrono"
            }
        }
    }

}

