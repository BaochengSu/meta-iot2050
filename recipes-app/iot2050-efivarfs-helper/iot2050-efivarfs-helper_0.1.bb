#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# This file is subject to the terms and conditions of the MIT License.  See
# COPYING.MIT file in the top-level directory.
#

DESCRIPTION = "Efivarfs Helper"
MAINTAINER = "baocheng.su@siemens.com"

SRC_URI = "file://iot2050-efivarfs-helper.tmpl"

TEMPLATE_FILES = "iot2050-efivarfs-helper.tmpl"

inherit dpkg-raw

do_install() {
    install -v -d ${D}/usr/sbin/
    install -v -m 755 ${WORKDIR}/iot2050-efivarfs-helper ${D}/usr/sbin/
}
