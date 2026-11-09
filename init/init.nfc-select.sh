#!/vendor/bin/sh
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

# init.nfc.mt6768.rc starts this script after data setup on NFC SKUs.
case "$(getprop ro.boot.product.hardware.sku)" in
    c3un|c3upg) ;;
    *) exit 0 ;;
esac

# Probe can complete asynchronously after module loading. A bounded wait in the
# selector service handles that without holding Android init's action queue.
attempt=0
while [ "$attempt" -lt 50 ]; do
    if [ -r /sys/nfc/chip_name ]; then
        IFS= read -r chip < /sys/nfc/chip_name || exit 1
        case "$chip" in
            thn31|pn557|sn110x)
                setprop vendor.nfc.chip "$chip"
                exit "$?"
                ;;
            *)
                log -p e -t nfc-selector "Unsupported NFC chip: $chip"
                exit 1
                ;;
        esac
    fi
    sleep 0.1
    attempt=$((attempt + 1))
done

log -p e -t nfc-selector "Timed out waiting for /sys/nfc/chip_name"
exit 1
