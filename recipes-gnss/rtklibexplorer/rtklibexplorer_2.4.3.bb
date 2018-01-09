SUMMARY = "RTKLib GPS real-time kinematic open-source software."
DESCRIPTION = "Open-source software to get accurate gps position information."
HOMEPAGE = "http://www.rtklib.com"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://readme.txt;md5=425f15fc0dc7e3abe85213c18f5bf1f6"

PR = "r0"

BB_STRICT_CHECKSUM = "0"

SRCREV = "${AUTOREV}"

#Try to merge original licenso from RTKLIB
SRC_URI = "git://github.com/rtklibexplorer/RTKLIB.git;branch=demo5 \
           file://base_m8t.cmd \
           file://rtkrcv.service \
           file://rtkrcv.init \
           file://rtkrcv.default \
           file://rtkrcv.conf \
           file://rtkstart.sh \
           file://rtkstop.sh \
           file://str2str.init \
           file://str2str.default \
"

S = "${WORKDIR}/git"

APPS = "pos2kml str2str rnx2rtkp convbin rtkrcv"
RTKCONFS = "rtkrcv.conf rtkstart.sh rtkstop.sh"

do_configure[noexec] = "1"

CFLAGS += "-I${S}/src"

inherit update-rc.d
INITSCRIPT_NAME = "rtkrcv"
INITSCRIPT_PARAMS = "start 17 2 3 4 5 . stop 23 0 6 1 ."

#inherit systemd
#SYSTEMD_SERVICE_${PN} = "rtkrcv.service"

do_compile() {
    for APP in ${APPS}; do
        oe_runmake -C ${S}/app/${APP}/gcc/
    done
}

do_install() {
    install -d ${D}${bindir}
    for APP in ${APPS}; do
        install -m 0755 ${B}/app/${APP}/gcc/${APP} ${D}${bindir}
    done

    # copy data files to /etc/rtklib/data
    install -d ${D}${sysconfdir}/rtklib/data
    install -m 0644 ${S}/data/* ${D}${sysconfdir}/rtklib/data/

    # install cmd files to /etc/rtklib/cmd/
    install -d ${D}${sysconfdir}/rtklib/cmd
    install -m 0644 ${WORKDIR}/*.cmd ${D}${sysconfdir}/rtklib/cmd/

    # deploy configuration files to /etc/rtklib
    for RTKCONF in ${RTKCONFS}; do
        install -m 0755 ${WORKDIR}/${RTKCONF} ${D}${sysconfdir}/rtklib
    done

    # set default receiver
    ln -sf cmd/base_m8t.cmd  ${D}${sysconfdir}/rtklib/base.cmd

    # deploy systemd service definition
    #install -d ${D}${sysconfdir}/systemd/system
    #install -m 0644 ${WORKDIR}/rtkrcv.service ${D}${sysconfdir}/systemd/system

    # deploy System V startup files
    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${WORKDIR}/rtkrcv.init ${D}${sysconfdir}/init.d/rtkrcv
    install -m 755 ${WORKDIR}/str2str.init ${D}${sysconfdir}/init.d/str2str

    #deploy default options
    install -d ${D}${sysconfdir}/default
    install -m 755 ${WORKDIR}/rtkrcv.default ${D}${sysconfdir}/default/rtkrcv
    install -m 755 ${WORKDIR}/str2str.default ${D}${sysconfdir}/default/str2str

}

CONFFILES_${PN} += "${sysconfdir}/default/rtkrcv ${sysconfdir}/default/str2str"

