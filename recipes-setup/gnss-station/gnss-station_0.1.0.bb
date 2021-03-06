SUMMARY = "navdata.net basestation configuration"
DESCRIPTION = "Configuration and data files for navdata.net GNSS basestations"
HOMEPAGE = "http://www.navdata.net"
LICENSE = "AGPLv3"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3e00ca6129dc8358315015204ab9fe15"

PR = "rc1"

RDEPENDS_${PN} = "python python-sleekxmpp"

SRC_URI = "file://LICENSE \
           file://runonce.init \
           file://zram.default \
           file://iptables.init \
           file://webroot \
           file://rrdcached.init \
           file://rrdcached.default \
           file://rrdcached.cron \
           file://rrd_rtkrcv.default \
           file://create_rrddb.sh \
           file://rrdbackup.sh \
           file://rrdrestore.sh \
           file://rrdgraph.sh \
           file://rrdgraph.volatiles \
           file://rrdgraph.cron \
           file://locupdate.sh \
           file://locupdate.cron \
           file://rtkrcv.cron \
           file://pushrawstream.sh \
           file://raw2rtcm.sh \
           file://raw2rtcm.default \
           file://locsrv.sh \
           file://loc2rtcm.sh \
           file://rtknavstatus.py \
           file://rtksolstatus.py \
           file://ecef2llh.py \
           file://rules.v4 \
           file://ntp.conf.template \
           file://navdatanet.default \
           file://RTCM3toXMPP.py \
           file://navcli.py \
           "

S = "${WORKDIR}"

inherit update-rc.d

INITSCRIPT_NAME = "rrdcached"
INITSCRIPT_PARAMS = "start 25 2 3 4 5 . stop 15 0 6 1 ."

do_install() {
    install -d ${D}/var/www/localhost/html
    install -m 0644 ${WORKDIR}/webroot/* ${D}/var/www/localhost/html
    ln -s /tmp/rrdgraph ${D}/var/www/localhost/html/volatile

    # deploy System V startup file
    install -d ${D}${sysconfdir}/rcS.d
    install -m 0755 ${WORKDIR}/runonce.init ${D}${sysconfdir}/rcS.d/S99runonce
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/rrdcached.init ${D}${sysconfdir}/init.d/rrdcached
    install -m 0755 ${WORKDIR}/iptables.init ${D}${sysconfdir}/init.d/iptables

    #deploy default options
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/raw2rtcm.default ${D}${sysconfdir}/default/raw2rtcm
    install -m 0644 ${WORKDIR}/rrdcached.default ${D}${sysconfdir}/default/rrdcached
    install -m 0644 ${WORKDIR}/rrd_rtkrcv.default ${D}${sysconfdir}/default/rrd_rtkrcv
    install -m 0644 ${WORKDIR}/navdatanet.default ${D}${sysconfdir}/default/navdatanet
    install -m 0644 ${WORKDIR}/zram.default ${D}${sysconfdir}/default/zram

    install -d ${D}${sysconfdir}/default/volatiles
    install -m 0644 ${WORKDIR}/rrdgraph.volatiles ${D}${sysconfdir}/default/volatiles/rrdgraph

    install -d ${D}${sysconfdir}/iptables
    install -m 0644 ${WORKDIR}/rules.v4 ${D}${sysconfdir}/iptables/rules.v4

    install -d ${D}${sysconfdir}/template
    install -m 0644 ${WORKDIR}/ntp.conf.template ${D}${sysconfdir}/template/ntp.conf

    install -d ${D}/var/lib/rrdcached/db
    install -d ${D}/var/lib/rrdcached/journal

    #cronjob for creating statistics images
    install -d ${D}${sysconfdir}/cron.d
    install -m 0644 ${WORKDIR}/rrdgraph.cron ${D}${sysconfdir}/cron.d/rrdgraph
    install -m 0644 ${WORKDIR}/locupdate.cron ${D}${sysconfdir}/cron.d/locupdate
    install -m 0644 ${WORKDIR}/rtkrcv.cron ${D}${sysconfdir}/cron.d/rtkrcv
    install -m 0644 ${WORKDIR}/rrdcached.cron ${D}${sysconfdir}/cron.d/rrdcached

    install -d ${D}/usr/local/bin
    install -m 0755 ${WORKDIR}/create_rrddb.sh ${D}/usr/local/bin/create_rrddb
    install -m 0755 ${WORKDIR}/rrdbackup.sh ${D}/usr/local/bin/rrdbackup
    install -m 0755 ${WORKDIR}/rrdrestore.sh ${D}/usr/local/bin/rrdrestore
    install -m 0755 ${WORKDIR}/rrdgraph.sh ${D}/usr/local/bin/rrdgraph
    install -m 0755 ${WORKDIR}/locupdate.sh ${D}/usr/local/bin/locupdate
    install -m 0755 ${WORKDIR}/ecef2llh.py ${D}/usr/local/bin/rtknavstatus
    install -m 0755 ${WORKDIR}/rtknavstatus.py ${D}/usr/local/bin/rtknavstatus
    install -m 0755 ${WORKDIR}/rtksolstatus.py ${D}/usr/local/bin/rtksolstatus
    install -m 0755 ${WORKDIR}/pushrawstream.sh ${D}/usr/local/bin/pushrawstream
    install -m 0755 ${WORKDIR}/raw2rtcm.sh ${D}/usr/local/bin/raw2rtcm
    install -m 0755 ${WORKDIR}/locsrv.sh ${D}/usr/local/bin/locsrv
    install -m 0755 ${WORKDIR}/loc2rtcm.sh ${D}/usr/local/bin/loc2rtcm
    install -m 0755 ${WORKDIR}/RTCM3toXMPP.py ${D}/usr/local/bin/RTCM3toXMPP
    install -m 0755 ${WORKDIR}/navcli.py ${D}/usr/local/bin/navcli
    
}

FILES_${PN} = "/var/www/localhost/html/* /usr/local/bin/* /etc/iptables/rules.v4 /etc/rcS.d/S99runonce /etc/init.d/* /etc/template/* /etc/default/* /etc/cron.d/* /var/lib/rrdcached/*"
CONFFILES_${PN} = "${sysconfdir}/default/rrdcached ${sysconfdir}/default/rrd_rtkrcv"

