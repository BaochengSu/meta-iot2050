# Copyright (c) Siemens AG, 2022-2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg

DESCRIPTION = "Secure Boot OTP key provisioning tool"

DEBIAN_BUILD_DEPENDS = "openssl, u-boot-tools, device-tree-compiler"

SRC_URI = " \
    file://keys/custMpk.crt \
    file://keys/custMpk.pem \
    file://keys/custSmpk.crt \
    file://keys/custSmpk.pem \
    file://keys/custBmpk.crt \
    file://keys/custBmpk.pem \
    file://make-otpcmd.sh \
    file://rules.tmpl"


# OTPCMD_KEYS ?= "keys/custMpk.pem keys/custSmpk.pem"

OTP_CMD_ACTION ?= "provision"
OTP_ENABLE_SECURE_BOOT ?= "n"

OTP_CMD_KEY_1ST ?= "custMpk.pem"
OTP_CMD_KEY_2ND ?= "custSmpk.pem"
OTP_CMD_KEY_3RD ?= ""

OTPCMD_BIN ?= "otpcmd.bin"
OTPCMD_OPTIONS = "${OTP_CMD_ACTION}"
OTPCMD_OPTIONS += " -1 '${OTP_CMD_KEY_1ST}' -2 ${OTP_CMD_KEY_2ND} -3 ${OTP_CMD_KEY_3RD}"
OTPCMD_OPTIONS += " -o ${OTPCMD_BIN}"

TEMPLATE_FILES = "rules.tmpl"
TEMPLATE_VARS += "OTPCMD_OPTIONS"

check_dummy_hash() {
    local OTPCMD_KEYS_full_path=
    for k in ${OTPCMD_KEYS}; do
        OTPCMD_KEYS_full_path="${OTPCMD_KEYS_full_path} ${S}/${k}"
    done

    ${S}/make-otpcmd.sh -t "${OTPCMD_KEYS_full_path}" 2>&1 | while IFS= read -r line; do
        if [ -n "${line}" ]; then
            bbwarn "${line}"
        fi
    done
}

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    # echo "OTP_CMD_KEY_1ST: _${OTP_CMD_KEY_1ST}_"
    # echo "OTP_CMD_KEY_2ND: _${OTP_CMD_KEY_2ND}_"
    # echo "OTP_CMD_KEY_3RD: _${OTP_CMD_KEY_3RD}_"
    # echo "OTP_ENABLE_SECURE_BOOT: _${OTP_ENABLE_SECURE_BOOT}_"
    # echo "OTP_CMD_ACTION: _${OTP_CMD_ACTION}_"

    deb_debianize
    mkdir -p ${S}/keys
    ln -f ${WORKDIR}/keys/* ${S}/keys/
    ln -f ${WORKDIR}/make-otpcmd.sh ${S}

    check_dummy_hash

    echo "${OTPCMD_BIN} /usr/lib/secure-boot-otp-provisioning/" > \
            ${S}/debian/secure-boot-otp-provisioning.install
}

dpkg_runbuild:append() {
    # remove keys from source archive
    gunzip ${WORKDIR}/${PN}_${PV}.tar.gz
    tar --delete -f ${WORKDIR}/${PN}_${PV}.tar ${PN}-${PV}/keys
    gzip ${WORKDIR}/${PN}_${PV}.tar
}
