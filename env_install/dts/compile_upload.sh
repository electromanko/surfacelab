#!/bin/bash

echo "Compile dts:"
for file in *.dts; do
#    if [ ! -f "./dtbo/${file%.*}.dtbo" ]; then
        echo -e "\t$file"
        dtc -W no-unit_address_vs_reg -O dtb -o "./dtbo/${file%.*}.dtbo" -b 0 -@ "$file"
#    fi
done

echo "Copy to /lib/firmware:"
for file in ./dtbo/*.dtbo; do
    echo -e "\t$file"
    sudo cp "$file" /lib/firmware/
done

update_initramfs () {
	if [ -f /boot/initrd.img-$(uname -r) ] ; then
		sudo update-initramfs -u -k $(uname -r)
	else
		sudo update-initramfs -c -k $(uname -r)
	fi
}

update_initramfs