#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import imp
import argparse
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
	
        self.register_plugin('xep_0030') # Service Discovery
        self.register_plugin('xep_0199') # XMPP Ping

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
    parser = argparse.ArgumentParser(description='Client for navdata.net.')
    parser.add_argument('message', metavar='command', type=str, nargs=1, help='command to send')
    args = parser.parse_args()

    global cred
    cred = imp.load_source('cred', '/etc/default/navdatanet')

    xmpp = SendMsgBot(cred.XMPPuser + '@navdata.net', cred.XMPPpwd, 'navdatanet@navdata.net', args.message[0])

    if xmpp.connect(address=('xmpp.navdata.net',5222)):
        xmpp.process(block=True)
    else:
        print("500:Unable to connect.")

