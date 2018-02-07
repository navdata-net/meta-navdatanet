DESCRIPTION = "Package group for navdata.net GNSS basestation."

LICENSE = "MIT"

inherit packagegroup

RDEPENDS_${PN} = "util-linux libgcc resolvconf parted e2fsprogs e2fsprogs-resize2fs cronie screen wireless-tools wpa-supplicant bluez5 iptables gettext-runtime wget curl socat ntpdate ntp nginx liberation-fonts rrdtool rrdcached python-psutil python-io pylongps rtklibexplorer gnss-station"

