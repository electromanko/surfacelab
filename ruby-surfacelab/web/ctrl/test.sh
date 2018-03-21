#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
echo SOURCE:
echo $SOURCE
cd ..
PW=`pwd`
echo $PW
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
echo $SCRIPTPATH