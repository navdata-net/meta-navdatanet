#!/bin/sh

[ -f /etc/default/navdatanet ] || {
  echo "/etc/default/navdatanet missing"
  sleep 60
  exit 1
  }

source /etc/default/navdatanet

nc localhost 3132 | RTCM3toXMPP -u "${XMPPuser}" -p "${XMPPpwd}"

