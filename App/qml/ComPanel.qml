import QtQuick 2.7

FocusScope {
    id: comPanel
    height: 200
    focus: true

    property bool opened: false
    property int fontSize: 18

    signal toggleOpenShut
    signal openRequested
    signal tabPressed
    signal animationDone

    ListModel {
        id: headerModel
        ListElement { name:"CompetFFCK"; image:""; imageSelected:"" }

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


    Behavior on y {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function displayPanel(buttonIndex) {
        if (buttonIndex===0) {
            competFFCKPanel.visible = true
        }
    }


}



