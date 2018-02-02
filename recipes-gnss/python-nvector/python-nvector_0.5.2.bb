SUMMARY = "Python nvector"
HOMEPAGE = "https://github.com/pbrod/nvector"

LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=b59808f7152cf0cd345c992f4957ea37"

SRC_URI[md5sum] = "0ac0d87333967f9b2329a7f76c5b3e76"
SRC_URI[sha256sum] = "0995540e319caaceb20d75ed57d8cf043eabd90caaf0322bb35f8e2baeeed567"

PYPI_PACKAGE = "nvector"

inherit pypi setuptools

RDEPENDS_${PN} += "${PYTHON_PN}-setuptools ${PYTHON_PN}-numpy ${PYTHON_PN}-geographiclib"

FILES_${PN}-doc = "${datadir}/nvector_docs"

