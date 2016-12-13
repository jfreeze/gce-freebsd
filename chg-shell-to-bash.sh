#!/bin/sh

echo "Change user `whoami` shell to bash"

ln -s ~/.shrc ~/.bash_login
sudo chsh -s /usr/local/bin/bash `whoami`

