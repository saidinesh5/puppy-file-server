import QtQuick 1.1
import com.nokia.meego 1.0

PageStackWindow {
  initialPage: Page {
    Rectangle {
      id: titleBar
      anchors.top: parent.top
      width: parent.width
      height: 100
      color: server.isAlive? "lightgreen":"orange"
      Text {
        anchors.centerIn : parent
        text: server.isAlive? "Server is ready to use!":"You are Offline!"
        color: "white"
        font.pointSize: 24
      }
    }

    Text {
      id: statusMessage
      property string host : "127.0.0.1"
      property int port : 8000
      anchors {
        top : titleBar.bottom
        horizontalCenter : parent.horizontalCenter
        margins: 20
      }
      text: server.isAlive? server.statusString(): "<center>Please connect to a network <br/>to use the Application.</center>"
      font.pointSize: 20
     }

    Rectangle{
      id: connectionList
      clip: true
      anchors{
        top: statusMessage.bottom
        margins: 40
      }
      radius: 10
      color: "black"
      width: parent.width
      height: parent.height - statusMessage.height - titleBar.height

      ListView {
        id: connectionsView
        model: server.connections()
        width: parent.width
        height: parent.height

        header: Rectangle {
          id: listHeader
          width: parent.width
          height: 60
          color: "black"
          radius: 10
          Text {
            color: "white"
            text: "  Incoming Connection..."
            font.pointSize: 16
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            color: "white"
            text: "Allow?  "
            font.pointSize: 16
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        footer: Rectangle {
          id: listFooter
          width: parent.width
          height: 60
          color: "black"
          radius: 10
          visible: (connectionsView.count == 0)
          Text {
            color: "lightgrey"
            text: "No Connections Yet"
            font.pointSize: 20
            anchors.centerIn: parent
          }
        }

        delegate: Rectangle {
          width: titleBar.width
          anchors.margins: 10

          height: 60
          radius: 5
          color: ((index % 2 == 0)?"white":"lightgrey")
          Text {
            font.pointSize: 16
            anchors.left: parent.left
            anchors.margins: 20
            anchors.verticalCenter: parent.verticalCenter
            text: model.connection.address
           }

          Switch{
            anchors.right: parent.right
            anchors.margins: 20
            anchors.verticalCenter: parent.verticalCenter
            checked: model.connection.allow
            onCheckedChanged: {
              model.connection.allow = checked
            }
          }
        }
      }

    }
  }
}
