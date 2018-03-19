#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import logging
import getpass
from optparse import OptionParser

import sleekxmpp

if sys.version_info < (3, 0):
    reload(sys)
    sys.setdefaultencoding('utf8')
else:
    raw_input = input


class SendMsgBot(sleekxmpp.ClientXMPP):

    def __init__(self, jid, password, recipient, message):
        sleekxmpp.ClientXMPP.__init__(self, jid, password)

        self.recipient = recipient
        self.msg = message

        self.add_event_handler("session_start", self.start)
        self.add_event_handler("message", self.rcvMsg)


    def start(self, event):
        self.send_presence()
        self.get_roster()

        self.send_message(mto=self.recipient, mbody=self.msg, mtype='chat')

    def rcvMsg(self, msg):
        if msg['type'] in ('chat', 'normal'):
            print(msg['body'])

        self.disconnect(wait=True)


if __name__ == '__main__':
    optp = OptionParser()

    # Output verbosity options.
    optp.add_option('-q', '--quiet', help='set logging to ERROR', action='store_const', dest='loglevel', const=logging.ERROR, default=logging.INFO)
    optp.add_option('-d', '--debug', help='set logging to DEBUG', action='store_const', dest='loglevel', const=logging.DEBUG, default=logging.INFO)
    optp.add_option('-v', '--verbose', help='set logging to COMM', action='store_const', dest='loglevel', const=5, default=logging.INFO)

    # JID and password options.
    optp.add_option("-j", "--jid", dest="jid", help="JID to use")
    optp.add_option("-p", "--password", dest="password", help="password to use")
    optp.add_option("-t", "--to", dest="to", help="JID to send the message to")
    optp.add_option("-m", "--message", dest="message", help="message to send")

    opts, args = optp.parse_args()

    #logging.basicConfig(level=opts.loglevel, format='%(levelname)-8s %(message)s')

    if opts.jid is None:
        opts.jid = raw_input("Username: ")
    if opts.password is None:
        opts.password = getpass.getpass("Password: ")
    if opts.to is None:
        opts.to = raw_input("Send To: ")
    if opts.message is None:
        opts.message = raw_input("Message: ")

    xmpp = SendMsgBot(opts.jid, opts.password, opts.to, opts.message)
    xmpp.register_plugin('xep_0030') # Service Discovery
    xmpp.register_plugin('xep_0199') # XMPP Ping

    if xmpp.connect(address=('xmpp.navdata.net',5222)):
        xmpp.process(block=True)
    else:
        print("500:Unable to connect.")

