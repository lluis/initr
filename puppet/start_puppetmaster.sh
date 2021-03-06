#!/bin/sh

# Starts a puppetmaster for development purposes

# If you have rails 2.3.2 installed and puppet 0.24.x, add this lines to puppetmasterd:
#
#  require 'rubygems'
#  gem 'rails', '2.2.2'
#

abspath=$(cd ${0%/*} && echo $PWD/${0##*/})
path_only=`dirname "$abspath"`

# Warning, development only: signs all certificate requests!
cat << EOF > $path_only/autosign.conf
*
EOF

cat << EOF > $path_only/fileserver.conf
# autogenerated from puppet/start_puppetmaster.sh
# do not edit, changes will be lost
[specific]
 path $path_only/files/specific/%h
 allow *
EOF

puppetmasterd --confdir $path_only --certname puppet --no-daemonize -l console -v $*
