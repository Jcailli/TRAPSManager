import QtQuick 2.7

Item {

    id: penaltyHeader

    property int fontSize: 18

    height: fontSize*1.5

    Rectangle {
        color: "black"
        anchors.fill: parent
    }
    Row {
        height: penaltyHeader.height
        spacing: 1
        Repeater {
            model: viewcontroller.gateCount
            Rectangle {
                width: fontSize*3-1
                height: penaltyHeader.height
                color: "gray"
                border.width: 1
                border.color: "white"
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: fontSize
                    text: ""+(index+1)

                }
            }
        }
    }
}

