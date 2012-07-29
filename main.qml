/*
 * Copyright: 2012 Dinesh Manajipet <saidinesh5@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above
 *   copyright notice, this list of conditions and the following disclaimer
 *   in the documentation and/or other materials provided with the
 *   distribution.
 * * Neither the name of the  nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

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
