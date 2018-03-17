#!/usr/bin/python

import os
import sys
import socket
import time
import datetime
import telnetlib
import psutil
import math


STATEMAP={ "-":0 , "single":1 , "dgps":2 , "float":3 , "fix":4 }


def get_ip_addresses(family):
  for interface, snics in psutil.net_if_addrs().items():
    for snic in snics:
      if snic.family == family:
        yield (interface, snic.address)


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


class RTKsite:

  SATS = 0; READS = 0
  LAT = 0; LON = 0; HGHT = 0
  VELX = 0; VELY = 0; VELZ = 0
  SGLX = 0; SGLY = 0; SGLZ = 0
  PREVX = 0; PREVY = 0; PREVZ = 0
  PREVDIST = 0;
  FLTX = 0; FLTY = 0; FLTZ = 0
  FLTSX = 0; FLTSY = 0; FLTSZ = 0
  FIXX = 0; FIXY = 0; FIXZ = 0
  FIXSX = 0; FIXSY = 0; FIXSZ = 0
  TIME = datetime.datetime(1,1,1)

  def setLocation(self,llh):
    self.LAT,self.LON,self.HGHT=llh.split(',')

  def setVelocity(self,xyz):
    (self.VELX,self.VELY,self.VELZ)=[float(x) for x in xyz.split(',')]

  def setSingle(self,xyz):
    self.PREVX=self.SGLX; self.PREVY=self.SGLY; self.PREVZ=self.SGLZ
    (self.SGLX,self.SGLY,self.SGLZ)=[float(x) for x in xyz.split(',')]
    TRX=self.SGLX-self.PREVX; TRY=self.SGLY-self.PREVY ; TRZ=self.SGLZ-self.PREVZ
    self.PREVDIST=math.sqrt((TRX)**2 + (TRY)**2 + (TRZ)**2)

  def setFloat(self,xyz):
    (self.FLTX,self.FLTY,self.FLTZ)=[float(x) for x in xyz.split(',')]

  def setFloatS(self,xyz):
    (self.FLTSX,self.FLTSY,self.FLTSZ)=[float(x) for x in xyz.split(',')]

  def setFix(self,xyz):
    (self.FIXX,self.FIXY,self.FIXZ)=[float(x) for x in xyz.split(',')]

  def setFixS(self,xyz):
    (self.FIXSX,self.FIXSY,self.FIXSZ)=[float(x) for x in xyz.split(',')]



class RTKRCVtelnet:

  ROVER = RTKsite()
  BASE = RTKsite()

  RUNTIME=datetime.timedelta()

  def __init__(self,password='admin',server='localhost',port=3130):
    self.PASSWORD=password
    self.SERVER=server
    self.PORT=port
    self.RTKRCV = telnetlib.Telnet(self.SERVER, self.PORT)
    self.RTKRCV.read_until("password: ")
    self.RTKRCV.write(self.PASSWORD + "\r\n")
    self.RTKRCV.read_until("rtkrcv> ",2)
    self.STATE = 0

  def send(self,command):
    self.RTKRCV.write(command+"\r\n")

  def setRuntime(self,time):
    hrs,mins,secs=time.split(':',3)
    secs=secs.split('.',1)[0]
    self.RUNTIME=datetime.timedelta(hours=int(hrs), minutes=int(mins), seconds=int(secs))

  def readStatus(self,timeout,callback=None):
    while True:
      LINE = self.RTKRCV.read_until("\r\n",timeout)
      if LINE == '': return

      if ':' in LINE:
        FIELD,VALUE=LINE.split(":",1)
        FIELD=FIELD.lstrip()
        FIELD=FIELD.rstrip()
        VALUE=VALUE.rstrip()
        VALUE=VALUE.lstrip()

        #print("<"+FIELD+"> = <"+VALUE+">")

        if FIELD == "rtklib version": self.VERSION=VALUE; self.TIMESTAMP=int(time.time()); print "timestamped"
        if FIELD == "rtk server state": self.ACTIVE=VALUE
        if FIELD == "processing cycle (ms)": self.PROCTIME=VALUE
        if FIELD == "positioning mode": self.MODE=VALUE
        if FIELD == "frequencies": self.FREQ=VALUE
        if FIELD == "accumulated time to run": self.setRuntime(VALUE)
        if FIELD == "cpu time for a cycle (ms)": self.CPUTIME=VALUE
        if FIELD == "missing obs data count": self.OBSMISSING=VALUE
        if FIELD == "# of input data rover": self.ROVER.READS=VALUE
        if FIELD == "# of input data base": self.BASE.READS=VALUE
        if FIELD == "# of input data corr": self.CORRECTIONS=VALUE
        if FIELD == "solution status": self.STATUS=VALUE ; self.STATE=STATEMAP[VALUE.lower()]
        if FIELD == "time of receiver clock rover": self.ROVER.TIME=VALUE
        if FIELD == "time sys offset (ns)": self.TIMEOFFSET=VALUE
        if FIELD == "solution interval (s)": self.SOLINTERVAL=VALUE
        if FIELD == "age of differential (s)": self.DIFFAGE=VALUE
        if FIELD == "ratio for ar validation": self.ARRATIO=VALUE
        if FIELD == "# of satellites rover": self.ROVER.SATS=VALUE
        if FIELD == "# of satellites base": self.BASE.SATS=VALUE
        if FIELD == "# of valid satellites": self.VALIDSATS=VALUE
        if FIELD == "GDOP/PDOP/HDOP/VDOP": self.DOP=VALUE
        if FIELD == "pos xyz single (m) rover": self.ROVER.setSingle(VALUE)
        if FIELD == "pos llh single (deg,m) rover": self.ROVER.setLocation(VALUE)
        if FIELD == "vel enu (m/s) rover": self.ROVER.setVelocity(VALUE)
        if FIELD == "pos xyz float (m) rover": self.ROVER.setFloat(VALUE)
        if FIELD == "pos xyz float std (m) rover": self.ROVER.setFloatS(VALUE)
        if FIELD == "pos xyz fixed (m) rover": self.ROVER.setFix(VALUE)
        if FIELD == "pos xyz fixed std (m) rover": self.ROVER.setFixS(VALUE)
        if FIELD == "pos llh (deg,m) base": self.BASE.setLocation(VALUE)
        if FIELD == "# of average single pos base": self.AVGBASEPOS=VALUE
        if FIELD == "vel enu (m/s) base": self.BASE.setVelocity(VALUE)
        if FIELD == "baseline length float (m)": self.BASELINEFLT=VALUE
        if FIELD == "baseline length fixed (m)": self.BASELINEFIX=VALUE
        if FIELD == "monitor port" and callback: callback(self)

  def close(self):
    self.RTKRCV.close()

if __name__ == "__main__":

  def updateRRD(rcv):
    rrd.add('rtkrcv_sys',str(psutil.cpu_freq().current) + ":" + str(psutil.cpu_percent()) + ":" + str(psutil.virtual_memory().available) + ":" + str(psutil.swap_memory().free),rcv.TIMESTAMP)
    rrd.add('rtkrcv_sglllh',str(rcv.ROVER.LAT) + ":" + str(rcv.ROVER.LON) + ":" + str(rcv.ROVER.HGHT),rcv.TIMESTAMP)
    rrd.add('rtkrcv_sglxyz',str(rcv.ROVER.SGLX) + ":" + str(rcv.ROVER.SGLY) + ":" + str(rcv.ROVER.SGLZ),rcv.TIMESTAMP)
    #rrd.add('rtkrcv_fltxyz',str(rcv.ROVER.FLTSX) + ":" + str(rcv.ROVER.FLTSY) + ":" + str(rcv.ROVER.FLTSZ),rcv.TIMESTAMP)
    rrd.add('rtkrcv_sat',str(rcv.ROVER.SATS) + ":" + str(rcv.BASE.SATS) + ":" + str(rcv.VALIDSATS),rcv.TIMESTAMP)
    rrd.add('rtkrcv_base',str(rcv.BASELINEFLT) + ":" + str(rcv.DIFFAGE),rcv.TIMESTAMP)
    #rrd.add('rtkrcv_rtime',rcv.RUNTIME.total_seconds(),rcv.TIMESTAMP)
    rrd.add('rtkrcv_stat',str(rcv.STATE) + ":" + str(rcv.ARRATIO),rcv.TIMESTAMP)

    if rcv.STATE > 0 :
      rrd.add('rtkrcv_solxyz',str(rcv.ROVER.SGLX) + ":" + str(rcv.ROVER.SGLY) + ":" + str(rcv.ROVER.SGLZ),rcv.TIMESTAMP)

    os.write(tty,'\033[H')
    os.write(tty,'%-5s: %-15s %.5s %24s\n' % (NIC,IP,'{:^5}'.format(rcv.STATUS),time.strftime('%d.%m.%Y %H:%M:%S %Z')))

    try:
      error = math.sqrt(float(rcv.ROVER.FLTSX)**2 + float(rcv.ROVER.FLTSY)**2 + float(rcv.ROVER.FLTSZ)**2)
    except:
      error = 0

    rrd.add('rtkrcv_var',str(error) + ":" + str(rcv.ROVER.PREVDIST),rcv.TIMESTAMP)

    try:
      os.write(tty,'LVL Sats: %2s  LLH: %11.8f  %12.8f  %7.2f\n' % (rcv.ROVER.SATS,float(rcv.ROVER.LAT),float(rcv.ROVER.LON),float(rcv.ROVER.HGHT)))
      os.write(tty,'RMT Sats: %2s  LLH: %11.8f  %12.8f  %7.2f\n' % (rcv.BASE.SATS,float(rcv.BASE.LAT),float(rcv.BASE.LON),float(rcv.BASE.HGHT)))
    except:
      pass


  time.sleep(5)
  LINK = dict(get_ip_addresses(socket.AF_INET))
  del LINK['lo']
  NIC,IP = LINK.popitem()
  tty = os.open('/dev/tty4',os.O_RDWR)
  os.write(tty,'\033[?25l')
  os.write(tty,chr(27) + '[2J')
  rrd=RRDcached()
  rcv=RTKRCVtelnet()
  rcv.send("status 1")
  rcv.readStatus(2,updateRRD)
  print("Latitude: "+rcv.ROVER.LAT)
  print("Longitutde: "+rcv.ROVER.LON)
  print("Height: "+rcv.ROVER.HGHT)
  rcv.close()
  os.close(tty)

