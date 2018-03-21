#!/bin/bash

#/sbin/route add default gw 192.168.7.1
sudo apt-get update && sudo apt-get upgrade &&
sudo apt-get install curl lighttpd mc minicom gawk zlib1g-dev libyaml-dev libsqlite3-dev sqlite3 libgmp-dev libgdbm-dev libffi-dev libgmp-dev libreadline6-dev libssl-dev gawk zlib1g-dev libyaml-dev libsqlite3-dev sqlite3 libgmp-dev libgdbm-dev libffi-dev libgmp-dev libreadline6-dev libssl-dev
#Install RVM stable with ruby:
sudo curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
sudo \curl -sSL https://get.rvm.io | sudo bash -s stable --ruby
sudo ./dts/compile_upload.sh
sudo cp ./uEnv/uEnv.txt /boot/uEnv.txt
sudo cp ./lighttpd/lighttpd.conf /etc/lighttpd/
rvmsudo gem install bundler
rvmsudo gem install ../beaglebone/beaglebone-2.2.6.gem
bundle install ../ruby-surfacelab/Gemfile
bundle install ../ruby-surfacelab/web/Gemfile
rvm alias create surfacelab ruby-2.4.1@surfacelab