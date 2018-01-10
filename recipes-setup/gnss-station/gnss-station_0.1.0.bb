SUMMARY = "navdata.net basestation configuration"
DESCRIPTION = "Configuration and data files for navdata.net GNSS basestations"
HOMEPAGE = "http://www.navdata.net"
LICENSE = "AGPLv3"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3e00ca6129dc8358315015204ab9fe15"

PR = "rc1"

RDEPENDS_${PN} = "python"

SRC_URI = "file://LICENSE \
           file://webroot \
           file://rrdcached.init \
           file://rrdcached.default \
           file://create_rrddb.sh \
           file://rrdgraph.sh \
           file://rtknavstatus.py \
           "

do_install() {
    install -d ${D}/var/www/localhost/html
    install -m 0644 ${WORKDIR}/webroot/* ${D}/var/www/localhost/html
    install -d ${D}/var/www/localhost/html/volatile

    # deploy System V startup file
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/rrdcached.init ${D}${sysconfdir}/init.d/rrdcached

    #deploy default options
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/rrdcached.default ${D}${sysconfdir}/default/rrdcached

    install -d ${D}/usr/local/bin
    install -m 0755 ${WORKDIR}/create_rrddb.sh ${D}/usr/local/bin/create_rrddb
    install -m 0755 ${WORKDIR}/rrdgraph.sh ${D}/usr/local/bin/rrdgraph
    install -m 0755 ${WORKDIR}/rtknavstatus.py ${D}/usr/local/bin/rtknavstatus
    
}

FILES_${PN} = "/var/www/localhost/html/* /usr/local/bin/* /etc/init.d/rrdcached /etc/default/rrdcached"
CONFFILES_${PN} = "${sysconfdir}/default/rrdcached"

