# TPM test README

## Build modified firmware with required enablers:

- RPMB
- fTPM
- StMM
- UEFI

```shell
./kas-container build kas-iot2050-boot.yml:kas/opt/tpm-test.yml
```

## Build modified example image

Check the git log for modifications.

```shell
./kas-container build kas-iot2050-example.yml:kas/opt/no-node-red.yml
```

## Get random from the fTPM:

Boot the IOT2050 with the firmware and example image above, then issue below
command to get a random number from the fTPM:

```shell
tpm2_getrandom 8 | hexdump -C
```

Check https://tpm2-tools.readthedocs.io/en/stable/ for command details. Note
choose the correct tpm2_tools version.
