#!/bin/sh

echo "Running FreeBSD GCE Instance setup..."
echo

sudo pkg install -y wget

echo "Setting up user environment for `whoami`"
echo
wget https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/user-env.sh
./user-env.sh
exit

echo "Installing base applications..."
wget https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/base-installs.sh

echo "Installing web applications..."
wget https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/web-installs.sh

echo "Configuring nginx..."
wget https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/nginx-setup.sh

echo
echo "Setup complete"
