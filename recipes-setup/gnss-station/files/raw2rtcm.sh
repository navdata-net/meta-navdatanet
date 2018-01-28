#!/bin/sh

CFGFILE="/etc/default/raw2rtcm"
LOCFILE="/tmp/location"

[ -f "${CFGFILE}" ] || {
    echo "Creating default configuration file."
    echo 'RAWFORMAT="ubx"' > "${CFGFILE}"
    echo 'MSGS="1002(1),1006(10),1010(1)"' >> "${CFGFILE}"
    }

echo "Reading configuration."
source "${CFGFILE}"
echo "Source data format: >${RAWFORMAT}<"
echo "RTCM messages: >${MSGS}<"

[ -f "${LOCFILE}" ] || {
    echo "Station location not yet determined. Restarting after 20 seconds..."
    sleep 20
    exit
    }

echo "Reading configuration"
source "${LOCFILE}"
echo "Latitude : >${LAT}<"
echo "Longitude: >${LON}<"
echo "Height   : >${HGHT}<"

/usr/bin/str2str -in tcpcli://localhost:3131#${RAWFORMAT} -out tcpsvr://:3141#rtcm3 -msg "${MSGS}" -p ${LAT} ${LON} ${HGHT} -t 1

