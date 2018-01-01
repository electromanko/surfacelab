#!/bin/sh
# filename: led_link_up

GPIO=70

if [ "$IFACE" = eth0 ]; then
    if [ ! -e /sys/class/gpio/gpio$GPIO/value ]; then
        echo $GPIO > /sys/class/gpio/export
        echo out > /sys/class/gpio/gpio$GPIO/direction
    fi
    
    #while  True  
    #do
        echo 1 > /sys/class/gpio/gpio$GPIO/value
    #    usleep 500000
    #    echo 0 > /sys/class/gpio/gpio67/value
    #    usleep 500000
    #done
fi