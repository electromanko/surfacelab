#!/bin/bash

#cd "$(dirname "$0")"
#thin -s 1 -C ../config.yml -R ../config.ru restart

/etc/init.d/surfacelab restart
sleep 14