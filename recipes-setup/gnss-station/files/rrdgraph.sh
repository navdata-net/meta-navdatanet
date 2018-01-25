#!/bin/sh

DBs="LAT:Lat:G:A:° LON:Lon:G:A:° HGHT:Hght:G:A:m ERR:Error:G:A:m RSAT:RovSats:G:A: BSAT:BasSats:G:A: VSAT:ValSats:G:A: ARR:ARratio:G:A: BLINE:Baseline:G:A:m DAGE:DiffAge:G:X:s RTIME:Runtime:C:N:s CPU:CPU:G:A:%% MEM:MemFree:G:A:kB STAT:Status:G:A:"
DBMs="FLTSX:FloatX:G:A:m FLTSY:FloatY:G:A:m FLTSZ:FloatZ:G:A:m CHZ:CPUhz:G:A:Hz"

export DURATIONS="30m 1d 2w 2y"
export TMPDIR="/tmp/rrdgraph"
export DBDIR="/var/lib/rrdcached/db"
export MIN="0.000000000"
export LOCATION="/tmp/location"

#[ -f /var/lib/rrdcached/db/rtkrcv_hght.rrd ] || /usr/local/bin/create_rrddb

RRD_GRAPH='rrdtool graph --daemon unix:/var/run/rrdcached.sock ${TMPDIR}/rtkrcv_${DBl}_${DUR}.png -a PNG --end now --start end-${DUR} --alt-autoscale "DEF:${DB}=${DBDIR}/rtkrcv_${DBl}.rrd:${DESC}:${AGGR}:step=1" "LINE1:${DB}#ff0000:${DESC}" "GPRINT:${DB}:AVERAGE:Average\: %.8lf${UNIT}"'

#echo FLUSHALL | socat - UNIX-CONNECT:/var/run/rrdcached.sock
#sleep 10

for ENTRY in ${DBs} ; do
  DB="`echo ${ENTRY} | cut -d ':' -f 1`"
  DBl="`echo ${DB} | tr '[:upper:]' '[:lower:]'`"

  DESC="`echo ${ENTRY} | cut -d ':' -f 2`"

  TEMP="`echo ${ENTRY} | cut -d ':' -f 3`"
  case TEMP in
    A) TYPE="ABSOLUTE" ;;
    C) TYPE="COUNTER" ;;
    D) TYPE="DERIVE" ;;
    G) TYPE="GAUGE" ;;
    *) TYPE="GAUGE" ;;
  esac

  TEMP="`echo ${ENTRY} | cut -d ':' -f 4`"
  case TEMP in
    A) AGGR="AVERAGE" ;;
    L) AGGR="LAST" ;;
    N) AGGR="MIN" ;;
    X) AGGR="MAX" ;;
    *) AGGR="AVERAGE" ;;
  esac

  UNIT="`echo ${ENTRY} | cut -d ':' -f 5`"

  export DB DBl DESC TYPE AGGR UNIT

  for DUR in ${DURATIONS} ; do
    export DUR
    COMMAND="`echo ${RRD_GRAPH} | envsubst`"
    echo ${COMMAND}
    eval ${COMMAND}
    done
  done

export NLAT="`rrdtool graph /tmp/test.png --daemon unix:/var/run/rrdcached.sock  --start -24hour 'DEF:data=/var/lib/rrdcached/db/rtkrcv_lat.rrd:Lat:AVERAGE' PRINT:data:AVERAGE:%.8lf|awk 'NR>1'`"
export NLON="`rrdtool graph /tmp/test.png --daemon unix:/var/run/rrdcached.sock  --start -24hour 'DEF:data=/var/lib/rrdcached/db/rtkrcv_lon.rrd:Lon:AVERAGE' PRINT:data:AVERAGE:%.8lf|awk 'NR>1'`"
export NHGHT="`rrdtool graph /tmp/test.png --daemon unix:/var/run/rrdcached.sock  --start -24hour 'DEF:data=/var/lib/rrdcached/db/rtkrcv_hght.rrd:Hght:AVERAGE' PRINT:data:AVERAGE:%.8lf|awk 'NR>1'`"

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
  killProcesses '/usr/bin/str2str'
  exit
  }

stopTransmission() {
  echo "Deleting ${LOCATION}"
  [ -f ${LOCATION}  ] && rm -f ${LOCATION}
  killAll
  }

[ "${NLAT}" = "nan" ] && stopTransmission
[ "${NLON}" = "nan" ] && stopTransmission
[ "${NHGHT}" = "nan" ] && stopTransmission

[ "${NLAT}" = "" ] && stopTransmission
[ "${NLON}" = "" ] && stopTransmission
[ "${NHGHT}" = "" ] && stopTransmission

expr ${NLAT} \< ${MIN} >/dev/null && stopTransmission
expr ${NLON} \< ${MIN} >/dev/null && stopTransmission
expr ${NHGHT} \< ${MIN} >/dev/null && stopTransmission

[ -f ${LOCATION} ] && . ${LOCATION}

echo "Writing new ${LOCATION}"
echo -e LAT=\"${NLAT}\"\\nLON=\"${NLON}\"\\nHGHT=\"${NHGHT}\"\\n > ${LOCATION}

[ "${NLAT}" != "${LAT}" ] && killAll
[ "${NLON}" != "${LON}" ] && killAll
[ "${NHGHT}" != "${HGHT}" ] && killAll

