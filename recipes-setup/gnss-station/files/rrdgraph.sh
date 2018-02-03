#!/bin/sh

CFG="/etc/default/rrd_rtkrcv"

[ -f "${CFG}" ] || exit 1
source "${CFG}"


export DURATIONS="30m 1d 2w 2y"
export TMPDIR="/tmp/rrdgraph"
export DBDIR="/var/lib/rrdcached/db"
export MIN="0.000000000"
export LOCATION="/tmp/location"

RTKPID="`pidof rtkrcv`" && for I in ${RTKPID} ; do chrt -r -a -p 30 $I ; done
RTKPID="`pidof str2str`" && for I in ${RTKPID} ; do chrt -r -a -p 20 $I ; done
RTKPID="`pidof transceiver`" && for I in ${RTKPID} ; do chrt -r -a -p 10 $I ; done

#[ -f /var/lib/rrdcached/db/rtkrcv_hght.rrd ] || /usr/local/bin/create_rrddb

RRD_GRAPH='rrdtool graph --daemon unix:/var/run/rrdcached.sock ${TMPDIR}/rtkrcv_${DBl}_${ITEM}_${DUR}.png -a PNG --end now --start end-${DUR} --alt-autoscale "DEF:${DB}=${DBDIR}/rtkrcv_${DBl}.rrd:${ITEM}:${AGGR}:step=1" "LINE1:${DB}#ff0000:${DESC}" "GPRINT:${DB}:AVERAGE:Average\: %.8lf${UNIT}"'

#echo FLUSHALL | socat - UNIX-CONNECT:/var/run/rrdcached.sock
#sleep 10

for ENTRY in ${DBs} ; do
  DB="`echo ${ENTRY} | cut -d ':' -f 1`"
  DBl="`echo ${DB} | tr '[:upper:]' '[:lower:]'`"

  ITEMS="`echo ${ENTRY} | cut -d ':' -f 2 | tr ',' ' '`"

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

  UNITS="`echo ${ENTRY} | cut -d ':' -f 5`"

  I=0
  for ITEM in ${ITEMS} ; do

    DESC="${ITEM}"
    I=$(($I + 1))
    UNIT="`echo ${UNITS} | cut -d ',' -f ${I}`"

    export DB DBl DESC ITEM TYPE AGGR UNIT

    for DUR in ${DURATIONS} ; do
      export DUR
      COMMAND="`echo ${RRD_GRAPH} | envsubst`"
      echo ${COMMAND}
      eval ${COMMAND}
      sleep 1
      done
    done
  done

