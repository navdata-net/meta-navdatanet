#!/bin/sh

CFG="/etc/default/rrd_rtkrcv"
XYZ="/tmp/xyz"
export LOCATION="/tmp/location"

export MIN="0.000000000"

declare -A MARGIN=( ["1d"]="1min" ["2w"]="1h" )
declare -A MINDATA=( ["1d"]="1080" ["2w"]="1008" )

export DBDIR="/var/lib/rrdcached/db"
export RRD="unix:/var/run/rrdcached.sock"

[ -f "${CFG}" ] || exit 1

source "${CFG}"

NOW="`date +%s`"

WINDOW="1d"
QLTY="sgl"


for QLTY in sol sgl ; do
  for WINDOW in 2w 1d ; do
    SOLVALS="`rrdtool fetch ${DBDIR}/rtkrcv_${QLTY}llh.rrd --daemon ${RRD} -a --start +${MARGIN[${WINDOW}]}-${WINDOW} AVERAGE | tail -n +3 | grep -v nan | wc -l`"
    echo "${SOLVALS} entries in ${WINDOW} of ${QLTY} > ${MINDATA[${WINDOW}]} ?"
    [ "${SOLVALS}" -gt "${MINDATA[${WINDOW}]}" ] && break
    done
  [ "${SOLVALS}" -gt "${MINDATA[${WINDOW}]}" ] && break
  done

export WINDOW
export QLTY

killProcesses() {
  PROCNAME="${1:-/usr/bin/transceiver}"
  PROCESSES="`grep -H "^${PROCNAME}" /proc/*/cmdline | cut -d '/' -f 3`"
  PROCESSES="`echo ${PROCESSES}`"
  for PROCESS in ${PROCESSES} ; do
    echo "Killing >${PROCNAME}< process #${PROCESS}"
    kill ${PROCESS}
    done
  }

killAll() {
  killProcesses '/usr/bin/transceiver'
  #killProcesses '/usr/bin/str2str'
  exit
  }

stopTransmission() {
  echo "Deleting ${LOCATION}"
  [ -f ${LOCATION}  ] && rm -f ${LOCATION}
  killAll
  }


[ "${QLTY}" = "sgl" -a "${SOLVALS}" -lt "${MINDATA[1d]}" ]  && {
  echo "Not enough confidence in location."
  stopTransmission
  }

echo "Using >${QLTY}< for window >${WINDOW}<."

TEMP="`rrdtool graph /tmp/test.png --daemon ${RRD} --start ${MARGIN[${WINDOW}]}-${WINDOW} DEF:lat=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Lat:AVERAGE DEF:lon=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Lon:AVERAGE DEF:hght=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Hght:AVERAGE PRINT:lat:AVERAGE:%.8lf PRINT:lon:AVERAGE:%.8lf PRINT:hght:AVERAGE:%.8lf | awk 'NR>1'`"

export NLAT="`echo ${TEMP} | cut -d ' ' -f 1`"
export NLON="`echo ${TEMP} | cut -d ' ' -f 2`"
export NHGHT="`echo ${TEMP} | cut -d ' ' -f 3`"

[ "${NLAT}" = "nan" -o "${NLON}" = "nan" -o "${NHGHT}" = "nan" ] && {
  echo "nan location data received."
  stopTransmission
  }

[ "${NLAT}" = "" -o "${NLON}" = "" -o "${NHGHT}" = "" ] && {
  echo "Empty location data received."
  stopTransmission
  }

expr ${NLAT} \< ${MIN} >/dev/null && stopTransmission
expr ${NLON} \< ${MIN} >/dev/null && stopTransmission
expr ${NHGHT} \< ${MIN} >/dev/null && stopTransmission

[ -f ${LOCATION} ] && . ${LOCATION}

echo "Writing new ${LOCATION}"
echo -e LAT=\"${NLAT}\"\\nLON=\"${NLON}\"\\nHGHT=\"${NHGHT}\"\\n > ${LOCATION}

[ "${NLAT}" != "${LAT}" ] && killAll
[ "${NLON}" != "${LON}" ] && killAll
[ "${NHGHT}" != "${HGHT}" ] && killAll

