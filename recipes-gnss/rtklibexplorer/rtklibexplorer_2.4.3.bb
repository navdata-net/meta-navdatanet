SUMMARY = "RTKLib GPS real-time kinematic open-source software."
DESCRIPTION = "Open-source software to get accurate gps position information."
HOMEPAGE = "http://www.rtklib.com"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://readme.txt;md5=425f15fc0dc7e3abe85213c18f5bf1f6"

PR = "r0"

BB_STRICT_CHECKSUM = "0"

SRCREV = "${AUTOREV}"

#Try to merge original licenso from RTKLIB
SRC_URI = " \
    git://github.com/rtklibexplorer/RTKLIB.git;branch=demo5 \
    file://base_m8t.cmd \
"

S = "${WORKDIR}/git"
# CUI apps listed in makeall.sh
APPS = "pos2kml str2str rnx2rtkp convbin rtkrcv"

do_configure[noexec] = "1"

CFLAGS += "-I${S}/src"
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

    # install cmd files to /etc/rtklib/cmd/
    install -d ${D}${sysconfdir}/rtklib/cmd
    install -m 0644 ${WORKDIR}/base_m8t.cmd ${D}${sysconfdir}/rtklib/cmd/

    # copy data files to /etc/rtklib/data
    install -d ${D}${sysconfdir}/rtklib/data
    install -m 0644 ${S}/data/* ${D}${sysconfdir}/rtklib/data/
}

#CONFFILES_${PN} += "${sysconfdir}/default/rtkrcv.conf"
