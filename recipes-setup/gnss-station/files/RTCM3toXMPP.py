#!/usr/bin/python -u

import sys
import optparse
import binascii
import logging
import time
import sleekxmpp

RTCM3_Preamble = 0xD3;
RTCM3_First_Data_Location = 3 # Zero based
RTCM3_Min_Size       = 6;
RTCM3_Max_Data_Length = 4095;
RTCM3_Max_Message_Length = RTCM3_Min_Size + RTCM3_Max_Data_Length;
RTCM3_Length_Location = 1 # Zero Based

domain='navdata.net'


class RTCM3toXMPP(sleekxmpp.ClientXMPP):

  def __init__(self, name, password):
    sleekxmpp.ClientXMPP.__init__(self, name+'@'+domain, password)
    self.nick=name
    self.navdata = 'navdata@'+domain
    self.room = name+'@conference.'+domain

    self.register_plugin('xep_0045') # MUC
    self.register_plugin('xep_0231') # BOB

    self.add_event_handler("session_start", self.session_start)
    self.add_event_handler("message", self.rcvMsg)


  def session_start(self, event):
    self.send_presence()

    try:
      self.get_roster()
    except IqError as err:
      logging.error('There was an error getting the roster')
      logging.error(err.iq['error']['condition'])
      self.disconnect()
    except IqTimeout:
      logging.error('Server is taking too long to respond')
      self.disconnect()

    self.plugin['xep_0045'].joinMUC(self.room, self.nick, wait=True)


  def rcvMsg(self, msg):
    if msg['type'] in ('chat', 'normal'):
      print "Received: " + msg['body']
      #msg.reply("Thanks for sending\n%(body)s" % msg).send()


  def xmit(self,msgbody):
    print msgbody
    self.send_message(mto=self.room, mbody=msgbody, mtype='groupchat')


  def xmitbin(self,msgbody,msgbinary):
    cid = self['xep_0231'].set_bob(msgbinary, 'application/octet-stream')
    msg = self.Message()
    msg['to'] = self.room
    msg['type'] = 'groupchat'
    msg['body'] = msgbody
    msg['bob']['cid'] = cid
    msg['bob']['type'] = 'application/octet-stream'
    msg['bob']['data'] = msgbinary
    msg.send()


if __name__ == "__main__":
  parser = optparse.OptionParser()
  parser.add_option("-u", "--user", type="string", dest="user", default="anonymous", help="XMPP logon user name (without domain)")
  parser.add_option("-p", "--password", type="string", dest="pwd", default="anonymous", help="XMPP logon password")
  (options, args) = parser.parse_args()
  print("Startup user: "+options.user+" pwd: "+options.pwd)
  #logging.basicConfig(level=logging.DEBUG, format='%(levelname)-8s %(message)s')
  xmpp = RTCM3toXMPP(options.user, options.pwd)
  xmpp.connect(address=('xmpp.'+domain,5222))
  xmpp.process()
  #last=time.now()
  delta=0
  while True:
    logging.debug("Read Byte")
    byte_preamble = bytearray(sys.stdin.read(1))
    if not byte_preamble : continue

    logging.debug("byte_preamble " + binascii.hexlify(byte_preamble))

    if byte_preamble[0] != RTCM3_Preamble : continue

    byte_length = bytearray(sys.stdin.read(2))
    MSG_LENGTH = int(binascii.hexlify(byte_length), 16)
    logging.debug("MSG_LENGTH " + str(MSG_LENGTH))

    if MSG_LENGTH > RTCM3_Max_Data_Length : continue

    byte_header = bytearray(sys.stdin.read(3))
    MSG_ID=(byte_header[0] << 4) + (byte_header[1] >> 4)
    logging.debug("Message ID " + str(MSG_ID))

    #MSG_StationID=((byte_header[1] & 0x0F) << 8) + (byte_header[2])
    #logging.debug("Station ID " + str(MSG_StationID))

    byte_header[1] = byte_header[1] & 0xF0
    byte_header[2] = 0x00

    byte_data = bytearray(sys.stdin.read(MSG_LENGTH))
    logging.debug("Message " + binascii.hexlify(byte_data))
    RTCM3msg = byte_preamble + byte_length + byte_header + byte_data
    xmpp.xmitbin(str(MSG_ID),RTCM3msg)

