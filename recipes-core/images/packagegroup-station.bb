DESCRIPTION = "Package group for navdata.net GNSS basestation."

LICENSE = "MIT"

inherit packagegroup

RDEPENDS_${PN} = "libgcc rpi-gpio parted e2fsprogs cronie iptables gettext-runtime curl socat ntpdate ntp nginx liberation-fonts rrdtool rrdcached python-io pylongps rtklibexplorer gnss-station"

