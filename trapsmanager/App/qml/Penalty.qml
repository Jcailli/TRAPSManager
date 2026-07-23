import QtQuick 2.7

Rectangle {

    property string value: ""
    property int fontSize: 18
    property bool selected: false
    property bool isKayakCrossMode: viewcontroller.competitionMode === 2

    height: fontSize*1.5
    width: fontSize*3

    color: {
        if (isKayakCrossMode) {
            return value == "CLR" ? "#6F6" :  // Vert pour CLR (Clear)
                   value == "FLT" ? "#FF6" :  // Orange pour FLT (Faute)
                   value == "RAL" ? "#F66" :  // Rouge pour RAL (Pénalité de sécurité)
                   value == "DNS" ? "#F00" :  // Rouge foncé pour DNS (Do Not Start)
                   value == "DNF" ? "#800" :  // Rouge très foncé pour DNF (Do Not Finish)
                   "white"
        } else {
            return value == "0" ? "#6F6" :
                   value == "2" ? "#FF6" :
                   value == "50" ? "#F66" :
                   "white"
        }
    }

    border.width: selected?4:0
    border.color: "black"

    Rectangle {
        width: parent.width
        height: 1
        color: "darkGray"
        anchors.verticalCenter: parent.bottom
    }

    Rectangle {
        width: 1
        height: parent.height
        color: "darkGray"
        anchors.horizontalCenter: parent.right
    }


    Text {
        color: "black"
        anchors.fill: parent
        font.pixelSize: fontSize
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: {
            if (isKayakCrossMode) {
                return value == "CLR" ? "CLR" :
                       value == "FLT" ? "FLT" :
                       value == "RAL" ? "RAL" :
                       value == "DNS" ? "DNS" :
                       value == "DNF" ? "DNF" :
                       value
            } else {
                return value
            }
        }
    }


}

