#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Su Baocheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg

SRC_URI += "git://git.ti.com/graphics/omap5-sgx-ddk-um-linux.git;branch=${SRC_BRANCH};rev=${SRC_REV} \
    file://debian"

SRC_BRANCH = "ti-img-sgx/thud/${PV}"
SRC_REV = "87d7e5c1e4db1bab048939c9719059d549c1e8dd"

S = "${WORKDIR}/git"
TARGET_PRODUCT = "ti654x"
DESTDIR = "/"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/
    deb_add_changelog
}


#######

#INITSCRIPT_NAME = "rc.pvr"
#INITSCRIPT_PARAMS = "defaults 8"

#inherit update-rc.d
