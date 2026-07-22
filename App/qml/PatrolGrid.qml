import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.1

FocusScope {
    id: patrolGrid

    height: 600
    width: 300

    property alias patrolListModel: patrolList.model
    property int fontSize: 18

    property int _penaltyCellWidth: fontSize*3
    property int _penaltyCellHeight: fontSize*1.5
    property int _penaltyCellCount: viewcontroller.gateCount
    property int _patrolCellWidth: fontSize*36+6
    property bool _shift: false
    property int _firstRowSelected: 0
    property int _lastRowSelected: 0

    signal tabPressed

    Flickable {
        id: gridContainer
        anchors.fill: parent
        contentWidth: patrolGrid.width
        contentHeight: patrolList.count * (fontSize*2.5 + 2)
        clip: true

        ListView {
            id: patrolList
            anchors.fill: parent
            model: bibList
            interactive: false

            delegate: Rectangle {
                id: patrolRow
                width: patrolGrid.width
                height: fontSize*2.5 + 2
                color: patrolRow.ListView.isCurrentItem ? "#E3F2FD" : "white"
                border.color: patrolRow.ListView.isCurrentItem ? "#2196F3" : "#E0E0E0"
                border.width: 1

                property int patrolIndex: index
                property var patrol: bibList.patrolAt(index)

                // Indicateur de statut de la patrouille
                Rectangle {
                    id: statusIndicator
                    width: 8
                    height: parent.height
                    color: {
                        if (!patrol) return "lightgray"
                        if (patrol.hasGapPenalty()) return "#F44336" // Rouge si écart > 15s
                        if (patrol.isComplete()) return "#4CAF50" // Vert si complète
                        return "#FF9800" // Orange si incomplète
                    }
                    anchors.left: parent.left
                    anchors.top: parent.top
                }

                // Informations de la patrouille
                Column {
                    anchors.left: statusIndicator.right
                    anchors.leftMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    spacing: 2

                    // Titre de la patrouille
                    Text {
                        text: patrol ? patrol.patrolId : "Patrouille " + (index + 1)
                        font.pixelSize: fontSize
                        font.bold: true
                        color: patrolRow.ListView.isCurrentItem ? "#1976D2" : "black"
                    }

                    // Informations des coureurs
                    Row {
                        spacing: 8
                        Repeater {
                            model: patrol ? patrol.bibCount : 0
                            delegate: Rectangle {
                                width: fontSize*8
                                height: fontSize*1.2
                                color: "#F5F5F5"
                                border.color: "#BDBDBD"
                                border.width: 1
                                radius: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!patrol || !patrol.bibAt(index)) return "-"
                                        var bib = patrol.bibAt(index)
                                        return bib.id() + " (" + bib.categ() + ")"
                                    }
                                    font.pixelSize: fontSize*0.8
                                    color: "black"
                                }
                            }
                        }
                    }

                    // Temps et pénalités
                    Row {
                        spacing: 4
                        
                        // Temps de départ
                        Rectangle {
                            width: fontSize*6
                            height: fontSize*1.2
                            color: "#E8F5E8"
                            border.color: "#4CAF50"
                            border.width: 1
                            radius: 2

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!patrol || patrol.startTime() <= 0) return "Départ"
                                    var startTime = new Date(patrol.startTime())
                                    return startTime.toLocaleTimeString(Qt.locale(), "hh:mm:ss.zzz")
                                }
                                font.pixelSize: fontSize*0.7
                                color: "black"
                            }
                        }

                        // Temps d'arrivée
                        Rectangle {
                            width: fontSize*6
                            height: fontSize*1.2
                            color: "#E3F2FD"
                            border.color: "#2196F3"
                            border.width: 1
                            radius: 2

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!patrol || patrol.finishTime() <= 0) return "Arrivée"
                                    var finishTime = new Date(patrol.finishTime())
                                    return finishTime.toLocaleTimeString(Qt.locale(), "hh:mm:ss.zzz")
                                }
                                font.pixelSize: fontSize*0.7
                                color: "black"
                            }
                        }

                        // Temps de course
                        Rectangle {
                            width: fontSize*6
                            height: fontSize*1.2
                            color: "#FFF3E0"
                            border.color: "#FF9800"
                            border.width: 1
                            radius: 2

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!patrol || patrol.runningTime() <= 0) return "Temps"
                                    var runningTime = patrol.runningTime()
                                    var minutes = Math.floor(runningTime / 60000)
                                    var seconds = Math.floor((runningTime % 60000) / 1000)
                                    var milliseconds = runningTime % 1000
                                    return minutes + ":" + (seconds < 10 ? "0" : "") + seconds + "." + (milliseconds < 100 ? "0" : "") + (milliseconds < 10 ? "0" : "") + milliseconds
                                }
                                font.pixelSize: fontSize*0.7
                                color: "black"
                            }
                        }

                        // Pénalité d'écart
                        Rectangle {
                            width: fontSize*4
                            height: fontSize*1.2
                            color: patrol && patrol.hasGapPenalty() ? "#FFEBEE" : "#E8F5E8"
                            border.color: patrol && patrol.hasGapPenalty() ? "#F44336" : "#4CAF50"
                            border.width: 1
                            radius: 2

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!patrol) return "Écart"
                                    var gap = patrol.timeGap()
                                    return gap + "s"
                                }
                                font.pixelSize: fontSize*0.7
                                color: patrol && patrol.hasGapPenalty() ? "#D32F2F" : "#2E7D32"
                            }
                        }
                    }
                }

                // Grille des pénalités par porte
                Grid {
                    id: penaltyGrid
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    columns: _penaltyCellCount
                    spacing: 1

                    Repeater {
                        model: _penaltyCellCount
                        delegate: Rectangle {
                            width: _penaltyCellWidth
                            height: _penaltyCellHeight
                            color: "#F5F5F5"
                            border.color: "#BDBDBD"
                            border.width: 1
                            radius: 1

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (!patrol) return ""
                                    var totalPenalty = patrol.totalPenaltyAtGate(index + 1)
                                    return totalPenalty > 0 ? totalPenalty : ""
                                }
                                font.pixelSize: fontSize*0.8
                                color: "black"
                                font.bold: true
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        patrolList.currentIndex = index
                    }
                }
            }
        }
    }

    Keys.onTabPressed: {
        tabPressed()
    }
}
