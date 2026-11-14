#!/vendor/bin/sh
case "$(getprop ro.boot.product.hardware.sku)" in
    c3un|c3upg) ;;
    *) exit 0 ;;
esac

prepare_pn557_node() {
    [ -c /dev/pn557 ] || return 1
    if [ ! -e /dev/nq-nci ] && [ ! -L /dev/nq-nci ]; then
        ln -s /dev/pn557 /dev/nq-nci || return 1
    fi
    [ -c /dev/nq-nci ]
}

attempt=0
while [ "$attempt" -lt 50 ]; do
    chip=
    if [ -r /sys/nfc/chip_name ]; then
        IFS= read -r chip < /sys/nfc/chip_name || :
    fi
    case "$chip" in
        thn31) [ -c /dev/tms_nfc ] || chip= ;;
        sn110x) [ -c /dev/nq-nci ] || chip= ;;
        pn557) prepare_pn557_node || chip= ;;
        *)
            chip=
            if prepare_pn557_node; then
                chip=pn557
            elif [ -c /dev/nq-nci ]; then
                chip=sn110x
            elif [ -c /dev/tms_nfc ]; then
                chip=thn31
            fi
            ;;
    esac
    if [ -n "$chip" ]; then
        log -p i -t nfc-selector "Starting NFC HAL for $chip"
        setprop vendor.nfc.chip "$chip"
        exit "$?"
    fi
    sleep 0.1
    attempt=$((attempt + 1))
done

log -p i -t nfc-selector "No usable NFC device found after timeout (chip_name: $(cat /sys/nfc/chip_name 2>/dev/null))"
exit 0
