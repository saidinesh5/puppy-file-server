#!/usr/bin/env python

#
#  Copyright: 2012 Dinesh Manajipet <saidinesh5@gmail.com>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are
#  met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following disclaimer
#    in the documentation and/or other materials provided with the
#    distribution.
#  * Neither the name of the  nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


import socket
import threading
import sys
import subprocess
import re

from SocketServer import ThreadingMixIn
from BaseHTTPServer import HTTPServer
from CGIHTTPServer import CGIHTTPRequestHandler

from PySide.QtCore import *
from PySide.QtGui import QApplication
from PySide.QtNetwork import QNetworkConfigurationManager
from PySide.QtDeclarative import QDeclarativeView

import os
os.chdir("/opt/puppy-file-server")

class Connection(QObject):
  '''Each connection is represented by a tuple of (string address, bool allow)'''
  def __init__(self, address,allow = False):
    QObject.__init__(self)
    self._address = address
    self._allow = allow

  def getAddress(self): return self._address
  addressChanged = Signal()

  def isAllowed(self): return self._allow
  def setAllowed(self, value):
    if(self._allow != value):
      self._allow = value
      self.statusChanged.emit()
  statusChanged = Signal()

  address = Property(str, getAddress, notify = addressChanged)
  allow = Property(bool, isAllowed, setAllowed, notify = statusChanged)


class ConnectionsModel(QAbstractListModel):
  ''' Keeps a list of all the active connections, whether allowed or not'''
  COLUMNS = ("connection",)
  def __init__(self):
    QAbstractListModel.__init__(self)
    self._connections = []#[Connection("127.0.0.1", True), Connection("localhost",True)]
    self.setRoleNames(dict(enumerate(ConnectionsModel.COLUMNS)))

  def rowCount(self, parent = QModelIndex()):
    return len(self._connections)

  def data(self, index, role = Qt.DisplayRole):
    if index.isValid() and role == ConnectionsModel.COLUMNS.index('connection'):
      return self._connections[index.row()]
    return None

  def status(self, value):
    #If the connection for this address already exists, return its status
    for connection in self._connections:
      if value == connection.address:
        return connection.allow

    #Else create a connection for this address, with the default status
    self.beginInsertRows(QModelIndex(),len(self._connections), len(self._connections))
    self._connections.append(Connection(value))
    self.endInsertRows()
    return False


class ElRequestHandler(CGIHTTPRequestHandler):
  '''Filters the incoming CGI requests using the ElServer's connections db'''
  def __init__(self, request, client_address, server):
    if ElServer.isAcceptable(client_address[0]):
      CGIHTTPRequestHandler.__init__(self, request, client_address,server)
    else:
      f = open('error.html','rb')
      errorPage = f.read()
      f.close()

      wfile = request.makefile('wb',0)
      rfile = request.makefile('rb',-1)
      try:
        raw_requestline = rfile.readline(65537)
        wfile.write("HTTP/1.0 200 OK\r\n")
        wfile.write("Connection: close\r\n")
        wfile.write("Content-Type: text/html; charset=UTF-8\r\n")
        wfile.write("Content-Length: %d\r\n"%(len(errorPage)))
        wfile.write("\r\n")
        wfile.write(errorPage)
      except socket.timeout,e: pass
      finally:
        if not wfile.closed:
          wfile.flush()
        wfile.close()
        rfile.close()

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    pass

class ElServer(QObject):
  '''This is the class to start and manage a http server
    in a separate thread.It also contains the necessary '''
  CONNECTIONS = ConnectionsModel()
  def __init__(self):
    QObject.__init__(self)
    self._httpd = None
    self._thread = None
    self._port = 8000
    self._alive = False

    #For starting and stopping the server based on network connectiviy changes
    self._nm = QNetworkConfigurationManager()
    self._nm.onlineStateChanged.connect(self._onlineStateChanged)

  def _onlineStateChanged(self, isOnline):
    if isOnline:
      #Restart the server to get the new IPs, if any
      self.stop()
      self.start()
    else:
      self.stop()

  @Slot()
  def start(self):
    # Allow only 1 instance of the server per object.
    # Also create the server only when we are connected.
    if self._httpd is None and self._nm.isOnline():
      self._thread = threading.Thread(target=self._thread_proc)
      self._thread.setDaemon(True)
      self._thread.start()
      print "Started HTTP server on port: ", self._port

  def _thread_proc(self):
    ''' The HTTP Server Thread'''
    while self._port < 10000:
      try:
        self._httpd = ThreadedHTTPServer(("", self._port),ElRequestHandler)
        break
      except:
        self._port += 1
    self._setAlive(True)
    self._httpd.serve_forever()
    self._thread = None

  def _isAlive(self):
    return self._alive

  def _setAlive(self,value):
    if value != self._alive:
      self._alive = value
      self.statusChanged.emit()

  statusChanged = Signal()
  isAlive = Property(bool, _isAlive, _setAlive, notify = statusChanged)

  @Slot()
  def stop(self):
    if self._httpd is not None:
      self._httpd.shutdown()
      self._httpd = None
      self._setAlive(False)
      print "Stopping Server..."

  def get_ips(self):
    ''' Gets a list of ip addresses the current device is using. '''
    ifconfig = subprocess.Popen('/sbin/ifconfig', stdout=subprocess.PIPE)
    stdout, stderr = ifconfig.communicate()

    ips = re.findall('addr:([^ ]+)', stdout)
    ips = filter(lambda ip: not ip.startswith('127.'), ips) or None
    return ips

  @Slot(result=unicode)
  def statusString(self):
    ips = self.get_ips()
    if ips is None:
      return ""
    return u'<center>Visit:<br>' + u'<br>or '.join(u'http://%s:%d/' % (ip, self._port) for ip in ips) + '<br/>on your computer, to access your files.</center>'

  @Slot(result=QObject)
  def connections(self):
    return self.CONNECTIONS

  @classmethod
  def isAcceptable(self, address):
    return ElServer.CONNECTIONS.status(address)

def main():
  app = QApplication(sys.argv)

  server = ElServer()
  server.start()

  view = QDeclarativeView()
  rootContext = view.rootContext()
  rootContext.setContextProperty('server', server)
  view.setSource('main.qml')
  view.showFullScreen()

  app.exec_()

  server.stop()

if __name__ == '__main__':
  main()
