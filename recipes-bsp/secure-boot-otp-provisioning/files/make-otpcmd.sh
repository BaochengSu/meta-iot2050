#!/bin/bash
#
# Copyright (c) Siemens AG, 2022-2023
#
# Authors:
#  Baocheng Su <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT

set -o errexit -o pipefail -o nounset

usage_exit()
{
	printf "%b" "Usage:\n"
	printf "%b" " $0 ACTION [OPTIONS]\n"
	printf "%b" "\n"
	printf "%b" "ACTION:\n"
	printf "%b" " provision  Make the otpcmd data for key provisioning "\
				"and/or SEBoot secure boot enabling.\n"
	printf "%b" " switch     Make the otpcmd data for switching the "\
				"current effective key.\n"
	printf "%b" "\n"
	printf "%b" "OPTIONS:\n"
	printf "%b" " -1, --slot1 PRI_KEY     Private key for OTP key slot 1.\n"
	printf "%b" " -2, --slot2 PRI_KEY     Private key for OTP key slot 2.\n"
	printf "%b" " -3, --slot3 PRI_KEY     Private key for OTP key slot 3.\n"
	printf "%b" " -e, --enable SIGN_KEY   Enable secure boot in OTP, only for provision.\n"
	printf "%b" "                         SIGN_KEY is used to sign the otpcmd data.\n"
	printf "%b" "                         It could be one of the keys in the slot.\n"
	printf "%b" " -o, --out OUT_FILE      Output otpcmd data to this file, by default otpcmd.bin\n"
	printf "%b" " -t, --test              Test if the dummy keys are used.\n"
	printf "%b" " -h, --help              Show this help\n"
	printf "%b" "\n"
	printf "%b" "Examples:\n"
	printf "%b" "\n"
	printf "%b" " 1. Program two keys, output to mydata.bin:\n"
	printf "%b" "    $0 provision -1 ./key-1 -2 ./key-2 -o ./mydata.bin\n"
	printf "%b" "\n"
	printf "%b" " 2. Enable secure boot in SEBoot, if key-1 is the key for OTP key slot 1:\n"
	printf "%b" "    $0 provision -e ./key-1\n"
	printf "%b" "\n"
	printf "%b" " 3. Revoke the current key, if currently using key is key-1, "\
		        "and the next key in the OTP slot is key-2\n"
	printf "%b" "    $0 switch -k \"key-1 key-2\"\n"
	printf "%b" "\n"
	printf "%b" " 4. Program 3 keys and enable secure boot at the same time. "\
					"(not recommended)\n"
	printf "%b" "    $0 provision -e key-1 -k \"key-1 key-2 key-3\"\n"
	exit "$1"
}

ITS=otpcmd.its
FIT_IMAGE=target.fit
X509_TEMPLATE=x509-template.txt
OTPCMD_BIN=otpcmd.bin

ENABLE_SECURE_BOOT=n
ENABLE_SECURE_BOOT_KEY=

OTP_KEY1=
OTP_KEY2=
OTP_KEY3=

check_dummy_key()
{
	local keyfile=$1
	local keyhash=$2

	DUMMY_KEY_HASHES=" \
	fb337ffb16be62fc4a97e62bf80faab1506b5f6e4231d6fec1dd01429ba016e3 \
	1e436ba092a4a134102ac68489cf64d5978fb28813d348b94331c98194dd7a09 \
	fcdf0f123e9a4eba4c8fd4f7b375e110c10fe4c4b916bb800c7a27466c5d791a"

	local hashstr
	hashstr=$(hexdump -ve '1/1 "%.2x"' "$keyhash")

	for dummy in $DUMMY_KEY_HASHES; do
		if [ "$dummy" = "$hashstr" ]; then
			echo "Warning: Dummy key $keyfile is used for OTP provisioning!"\
			     "Please make sure this is what you really want!" 1>&2;
			return			
		fi
	done

	echo "Key $keyfile is not a dummy key."
}

gen_pubkey_hash()
{
	[ -n "$OTP_KEY1" ]  && openssl rsa -in "$OTP_KEY1" -pubout -outform der 2>/dev/null | \
		openssl dgst -sha256 -binary -out key1.sha256 \
		&& check_dummy_key "$OTP_KEY1" key1.sha256

	[ -n "$OTP_KEY2" ]  && openssl rsa -in "$OTP_KEY2" -pubout -outform der 2>/dev/null | \
		openssl dgst -sha256 -binary -out key2.sha256 \
		&& check_dummy_key "$OTP_KEY2" key2.sha256

	[ -n "$OTP_KEY3" ]  && openssl rsa -in "$OTP_KEY3" -pubout -outform der 2>/dev/null | \
		openssl dgst -sha256 -binary -out key3.sha256 \
		&& check_dummy_key "$OTP_KEY3" key3.sha256
}

gen_its()
{
	cat << EOF > $ITS
/dts-v1/;

/ {
	description = "IOT2050 secure boot OTP command data";
	creator = "IOT2050 secure boot OTP provisioning tool";

	images {
EOF

	if [[ "$ACTION" == "provision" ]] && [ -n "$OTP_KEY1" ]; then
		cat << EOF >> $ITS
		custKey1Hash {
			description = "Customer 1st public key hash";
			data = /incbin/("./key1.sha256");
			type = "script";
			compression = "none";
		};
EOF
	fi

	if [[ "$ACTION" == "provision" ]] && [ -n "$OTP_KEY2" ]; then
		cat << EOF >> $ITS
		custKey2Hash {
			description = "Customer 2nd public key hash";
			data = /incbin/("./key2.sha256");
			type = "script";
			compression = "none";
		};
EOF
	fi

	if [[ "$ACTION" == "provision" ]] && [ -n "$OTP_KEY3" ]; then
		cat << EOF >> $ITS
		custKey3Hash {
			description = "Customer 3rd public key hash";
			data = /incbin/("./key3.sha256");
			type = "script";
			compression = "none";
		};
EOF
	fi

	cat << EOF >> $ITS
	};

	options {
		version = <1>;
EOF

	if [[ "$ACTION" == "provision" ]]; then
		local option_index=1

		if [ -n "$OTP_KEY1" ]; then
			cat << EOF >> $ITS
		option-${option_index} {
			cmd = "setup-customer-key-hash";
			key-hash = "custKey1Hash";
			key-hash-id = <0>;
			key-hash-type = "sha256";
		};
EOF
			option_index=$((option_index+1))
		fi

		if [ -n "$OTP_KEY2" ]; then
			cat << EOF >> $ITS
		option-${option_index} {
			cmd = "setup-customer-key-hash";
			key-hash = "custKey2Hash";
			key-hash-id = <1>;
			key-hash-type = "sha256";
		};
EOF
			option_index=$((option_index+1))
		fi

		if [ -n "$OTP_KEY3" ]; then
			cat << EOF >> $ITS
		option-${option_index} {
			cmd = "setup-customer-key-hash";
			key-hash = "custKey3Hash";
			key-hash-id = <2>;
			key-hash-type = "sha256";
		};
EOF
			option_index=$((option_index+1))
		fi

		if [[ "$ENABLE_SECURE_BOOT" == "y" ]]; then
			cat << EOF >> $ITS
		option-${option_index} {
			cmd = "enable-secure-boot";
		};
EOF
		fi 
	else
		cat << EOF >> $ITS
		option-1 {
			cmd = "switch-customer-key-hash";
		};
EOF
	fi

	cat << EOF >> $ITS
	};
};
EOF
}

# Generate x509 Template
gen_template()
{
[ -f "$X509_TEMPLATE" ] && rm $X509_TEMPLATE
cat << 'EOF' > $X509_TEMPLATE
[ req ]
distinguished_name     = req_distinguished_name
x509_extensions        = v3_ca
prompt                 = no
dirstring_type         = nobmp

[ req_distinguished_name ]
C                      = CN
ST                     = Sichuan
L                      = Chengdu
O                      = Siemens AG
OU                     = SEWC
CN                     = Siemens AG
emailAddress           = IOT2000.industry@siemens.com

[ v3_ca ]
basicConstraints       = CA:true
1.3.6.1.4.1.294.1.3    = ASN1:SEQUENCE:swrv
1.3.6.1.4.1.294.1.34   = ASN1:SEQUENCE:sysfw_image_integrity
1.3.6.1.4.1.294.1.35   = ASN1:SEQUENCE:sysfw_image_load

[ swrv ]
swrv = INTEGER:0

[ sysfw_image_integrity ]
shaType                = OID:2.16.840.1.101.3.4.2.3
shaValue               = FORMAT:HEX,OCT:TEST_IMAGE_SHA_VAL
imageSize              = INTEGER:TEST_IMAGE_LENGTH

[ sysfw_image_load ]
destAddr = FORMAT:HEX,OCT:fffffffe
authInPlace = INTEGER:2
EOF
}

clean()
{
	rm -f key*.sha256
	rm -f $ITS
	rm -f $FIT_IMAGE
	rm -f $X509_TEMPLATE
	rm -f "$OTPCMD_BIN".1st
}

OPTIONS_SHORT='1:2:3:e:ho:t'
OPTIONS_LONG='slot1:,slot2:,slot3:,enable:,help,out:,test'
# shellcheck disable=2251
! TEMP=$(getopt -o "$OPTIONS_SHORT" --long "$OPTIONS_LONG" --name "$0" -- "$@")

if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
	echo 'Terminating...' >&2
	usage_exit 1
fi

eval set -- "$TEMP"
unset TEMP

while true; do
	case "$1" in
		'-1'|'--slot1')
			OTP_KEY1=$2
			shift 2
			continue
		;;
		'-2'|'--slot2')
			OTP_KEY2=$2
			shift 2
			continue
		;;
		'-3'|'--slot3')
			OTP_KEY3=$2
			shift 2
			continue
		;;
		'-e'|'--enable')
			ENABLE_SECURE_BOOT=y
			ENABLE_SECURE_BOOT_KEY="$2"
			shift 2
			continue
		;;
		'-o'|'--out')
			OTPCMD_BIN=$2
			shift 2
			continue
		;;
		'-t'|'--test')
			DUMMY_KEY_TEST=y
			# parse_key_files "$2"
			# gen_pubkey_hash
			# rm -f key*.sha256
			# exit 0
			shift
			continue
		;;
		'-h'|'--help')
			usage_exit 0
		;;
		'--')
			shift
			break
		;;
		*)
			echo 'Internal error!' >&2
			exit 3
		;;
	esac
done

if [[ $# -lt 1 ]]; then
    echo "$0: action (provision/switch) must be provided."
	echo 
	usage_exit 1
fi

ACTION=
# Parse the action
case "$1" in
	provision)
		if [[ -z "ENABLE_SECURE_BOOT_KEY" ]]; then
			if [ -n "$OTP_KEY1" ]; then
				SIGNING_KEY=$OTP_KEY1
			else if [ -n "$OTP_KEY2" ]; then
				SIGNING_KEY=$OTP_KEY2
			else if [ -n "$OTP_KEY3" ]; then
				SIGNING_KEY=$OTP_KEY3
			else
				echo "At least 1 key file should be provided!"
				echo
				usage_exit 1
			fi
		else
			if [ -n "$OTP_KEY1" ] || [ -n "$OTP_KEY2" ] || [ -n "$OTP_KEY3" ]; then
				echo "Warning: combine the key provisioning and secure boot enabling is not recommended!"
			fi
			SIGNING_KEY=$ENABLE_SECURE_BOOT_KEY
		fi
		ACTION=provision
		;;
	switch)
		if [ -n "$OTP_KEY1" ] && [ -n "$OTP_KEY2" ]; then
			SIGNING_KEY=$OTP_KEY1
			SIGNING_KEY2=$OTP_KEY2
		else if [ -n "$OTP_KEY2" ] && [ -n "$OTP_KEY3" ]; then
			SIGNING_KEY=$OTP_KEY2
			SIGNING_KEY2=$OTP_KEY3
		else
			echo "Exactly 2 adjacent key files must be provided!"
			echo
			usage_exit 1
		fi
		ACTION=switch
		;;
	*)
		echo "Wrong action, must be one of provision/switch"
		echo
		usage_exit 1
		;;
esac

[ -n "$OTP_KEY1" ] && [ -f "$OTP_KEY1" ] || { echo "key file $OTP_KEY1 does not exist!"; exit 1; }
[ -n "$OTP_KEY2" ] && [ -f "$OTP_KEY2" ] || { echo "key file $OTP_KEY2 does not exist!"; exit 1; }
[ -n "$OTP_KEY3" ] && [ -f "$OTP_KEY3" ] || { echo "key file $OTP_KEY3 does not exist!"; exit 1; }

if [[ "$ENABLE_SECURE_BOOT" == "y" ]]; then
	[ -f "$ENABLE_SECURE_BOOT_KEY" ] || \
		{ echo "key file $ENABLE_SECURE_BOOT_KEY does not exist!"; exit 1; }
fi

clean
rm -f "$OTPCMD_BIN"

if [[ "$ACTION" == "provision" ]]; then
	gen_pubkey_hash
fi

gen_its

mkimage -f $ITS $FIT_IMAGE

sign_image()
{
	local key=$1
	local image=$2
	local image_signed=$3
	local temp_x509=x509-temp.cert
	local sha_value
	local bin_size

	rm -f $temp_x509 "$image".cert $X509_TEMPLATE

	sha_value=$(openssl dgst -sha512 -hex "$image" | sed -e "s/^.*= //g")
	# shellcheck disable=2002
	bin_size=$(cat "$image" | wc -c)

	gen_template

	sed -e "s/TEST_IMAGE_LENGTH/$bin_size/"	\
		-e "s/TEST_IMAGE_SHA_VAL/$sha_value/" $X509_TEMPLATE > $temp_x509
	
	openssl req -new -x509 -key "$key" -nodes -outform DER -out "$image".cert \
		-config $temp_x509 -sha512
	
	cat "$image".cert "$image" > "$image_signed"
	
	rm -f $temp_x509 "$image".cert $X509_TEMPLATE
}

# if [[ "$ACTION" == "provision" ]] && [[ "$ENABLE_SECURE_BOOT" == "y" ]]; then
# 	SIGNING_KEY=$ENABLE_SECURE_BOOT_KEY
# else
# 	SIGNING_KEY=$OTP_KEY1
# fi

sign_image "$SIGNING_KEY" $FIT_IMAGE "$OTPCMD_BIN"

if [ "$ACTION" == "switch" ]; then
	mv "$OTPCMD_BIN" "$OTPCMD_BIN".1st
	sign_image "$SIGNING_KEY2" "$OTPCMD_BIN".1st "$OTPCMD_BIN"
fi

clean
