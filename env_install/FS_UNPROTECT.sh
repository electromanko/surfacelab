#!/bin/bash

mount -o remount,rw /ro
mount --bind /ro/var/lib/cloud9/surfacelab /var/lib/cloud9/surfacelab