#!/usr/bin/python

import os
import sys
import socket
import time
import datetime
import telnetlib
import math


STATEMAP={ "-":0 , "single":1 , "dgps":2 , "float":3 , "fix":4 }


class RRDcached:

  def __init__(self,server='localhost',port=42217):
    self.SERVER=server
    self.PORT=port

    try:
      self.RRD = telnetlib.Telnet(self.SERVER, self.PORT)
    except socket.error, msg:
      print >>sys.stderr, msg
      sys.exit(1)

  def add(self,DB,value,time=int(time.time())):
    command = 'update ' + DB + '.rrd ' + str(time) + ':' + str(value)
    self.RRD.write(command+"\n")
    reply = self.RRD.read_until("\n",1)
    reply = reply.rstrip()
    print >>sys.stderr, command + ': ' + reply


class RTKMONtelnet:

  LAT=0
  LON=0
  HGHT=0

  def __init__(self,server='localhost',port=3134):
    self.SERVER=server
    self.PORT=port
    self.RTKRCV = telnetlib.Telnet(self.SERVER, self.PORT)
    LINE = self.RTKRCV.read_until("\r")

  def readStatus(self,callback=None):
    while True:
      LINE = self.RTKRCV.read_until("\n\r")

      self.TIMESTAMP=(datetime.datetime.strptime(LINE.split(".",1)[0] + " UTC",'%Y/%m/%d %H:%M:%S %Z') - datetime.datetime(1970,1,1)).total_seconds()
      DATA=LINE.split()
      self.LAT=DATA[2]
      self.LON=DATA[3]
      self.HGHT=DATA[4]

      if callback: callback(self)


  def close(self):
    self.RTKRCV.close()

if __name__ == "__main__":

  def updateRRD(rcv):
    rrd.add('rtkrcv_solllh',str(rcv.LAT) + ":" + str(rcv.LON) + ":" + str(rcv.HGHT),rcv.TIMESTAMP)

  #time.sleep(5)
  rrd=RRDcached()
  rcv=RTKMONtelnet()
  rcv.readStatus(updateRRD)
  print("Latitude: " + str(rcv.LAT))
  print("Longitutde: " + str(rcv.LON))
  print("Height: " + str(rcv.HGHT))
  rcv.close()

