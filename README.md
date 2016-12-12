# gce-freebsd

    \curl -sSL https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/freebsd-setup.sh | bash -s stable

# What it does

This script sets the user environment found in the <code>user-env.sh</code>, 
installs the base applications in <code>base-installs.sh</code>, 
installs the web applications in <code>web-installs.sh</code>,
sets up the config files for nginx (but prompts the user that installation must be run manually).

Once run, the server is ready for web application deployment.
