#!/bin/sh

echo "Running FreeBSD GCE Instance setup..."
echo

echo "Setting up user environment for `whoami`"
echo
curl https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/user-env.sh > /tmp/user-env.sh
/bin/sh /tmp/user-env.sh

echo "Installing base applications..."
curl https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/base-installs.sh > /tmp/base-installs.sh
/bin/sh /tmp/base-installs.sh

echo "Installing web applications..."
curl https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/web-installs.sh > /tmp/web-installs.sh
/bin/sh /tmp/web-installs.sh

echo "Copying extra config files..."
curl https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/chg-shell-to-bash.sh > /tmp/chg-shell-to-bash.sh

echo "Configuring nginx..."
curl https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/nginx-setup.sh > /tmp/nginx-setup.sh
chmod 755 /tmp/nginx-setup.sh

echo
echo "Run /tmp/chg-shell-to-bash.sh for compatability with edeliver"
echo 
echo "Nginx needs DOMAIN manually setup."
echo "Configure /tmp/nginx-setup.sh and run /tmp/nginx-setup.sh to complete"

echo
echo "Setup complete"
