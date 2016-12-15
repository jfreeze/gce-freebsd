# About

This is the project that I used to deploy [ElixirConf.com](http://elixirconf.com).

It is a collection of scripts and instructions for setting up a 
cloud web server, along with DNS, SSL, and deploying a Phoenix 
web application using Distillery and eDeliver.

The scripts (and these instructions) were written to assist me in setting up
new web servers quickly. With them I can create a VM, setup a SSL website,
and deploy a local Phoenix app in under 10 minutes.

This guide should be of some help to anyone wanting to setup a website with Phoenix, even
if you are not using FreeBSD or GCE. Just note, that some scripts will need to be
customized to your situation. I will try to point that out wherever possible.

To use the scripts provided here, you will need to have a GCE account and have
the [gcloud SDK](https://cloud.google.com/sdk/downloads) installed on your computer.

Also, you will need to download this project to get access to some of the gcloud helper
scripts to run on your local computer.

    git clone git@github.com:jfreeze/gce-freebsd.git

# Choices

The setup includes instructions on creating a 
FreeBSD instance on [Google Compute Engine](https://cloud.google.com/compute/),
setting up DNS using [DNSimple](https://dnsimple.com),
free SSL cert generation using [Letsencrypt](https://letsencrypt.org/) for https transport,
and [Nginx](https://nginx.org/en/) to handle web services.

I should point out that the deployment configuration contained herein does not yet
cover DB setup and deployment, and for now is a simple configuration where the
build and deploy machines are the same machine. However, it is a simple task to
to extend the examples shown here to have a separate build machine and deploy machine.

At some future date I will extend the examples and cover deployment where databases
and data migration are involved.

# Overview

 1. Create a GCE Instance
 1. Configure nginx
 1. Install and configure Distillery
 1. Install and configure eDeliver
 1. Deploy Phoenix app to web server
 1. Create SSL cert from Letsencrypt
 1. Configure nginx for SSL

# Getting Started

The first order of business is to create a VM instance on the Google Compute Engine cloud service.

## Create a GCE Project

If you don't already have a [Google Compute Engine](https://cloud.google.com/compute) account, you will need to get one.
I originally started these scripts for [AWS](https://aws.amazon.com), but switched to GCE because of their better (read faster)
network, and scaling to faster CPU's with more RAM was more economical.

Once in GCE, you will need to create a project to run your
Google Compute Engine VM's under, if you don't already have one. 
Google allows up to five projects.

Since this is a seldom done task and is easy enough to do, I am not providing
and console oriented way of creating a project. 

Simply open up your [GCE console](https://console.cloud.google.com/iam-admin/iam/)
in a web browser, click the three horizontal bars (the hamburger menu) in the upper
left of the page, select <code>IAM &amp; Admin</code>, then click on 
<code>All Projects</code>. You should see a <code>+ CREATE PROJECT</code> 
link in the top center of the page to create a new project.

## Create the VM Network 

I prefer a customized a network so I don't have unused firewall rules in it
and I like GCE's target tags that allow firewall rules to be applied to selected
machines only. For this reason, I delete the default network and firewall rules
on new projects. Notice that the examples shown here are for the GCE project 
named <code>elixirconf</code>. You will need to change <code>elixirconf</code> to
the name of your project.

    # delete default firewall rules
    ./gcloud-compute-firewall-rules-delete.sh elixirconf

    # delete default network
    gcloud compute networks delete "default" \
      --project elixirconf

### Create a Network

Next, create a network. I used the name <code>elixirconf-net</code>.

    ./gcloud-compute-network-create.sh elixirconf elixirconf-net

### Create firewall rules

The <code>gcloud-compute-firewall-rules-create.sh</code> script creates
firewall rules for private cloud access, http, https, ping and ssh.

    ./gcloud-compute-firewall-rules-create.sh elixirconf elixirconf-net

## Create a Server

The <code>gcloud-compute-instance-create.sh</code> script creates 
a FreeBSD 11.0-RELEASE machine with the smallest configuration of
CPU and RAM possible. It runs about $5 per month. I chose the name
<code>elixirconf-www-01</code> for the name of this web server VM.

    ./gcloud-compute-instance-create.sh elixirconf elixirconf-www-01 elixirconf-net

### Set a Static IP

If you want, you can get a reserved static IP for your new VM instance.
Since this is a one time task, it is simple enough to do
it from the GCE web console.

In the console, click on the instance name, click edit at the top of the page,
scroll down to <code>External IP</code> and change the address from 
<code>ephemeral</code> to <code>New static IP address...</code>.
You will need to create a name for your static IP. 
I used <code>elixirconf-com</code>.
Save the changes.

### Connect to the new VM Instance (Your web server)

I find the <code>gcloud compute ssh</code> command useful, but clunky,
so I always setup <code>ssh</code> access to my servers.

When you first installed <code>gcloud</code> and ran <code>gcloud init</code>,
it created an <code>ssh key</code> for you called <code>google_compute_engine</code>.

    ls -l ~/.ssh/
    total 64
    -rw-r--r--  1 jimfreeze  staff   404 Dec 13 12:28 config
    -rw-------  1 jimfreeze  staff  1675 Nov 22 16:30 google_compute_engine
    -rw-r--r--  1 jimfreeze  staff   402 Nov 22 16:30 google_compute_engine.pub
    -rw-r--r--  1 jimfreeze  staff  1700 Dec 12 21:26 google_compute_known_hosts

Connecting to your server one time with gcloud will update project ssh metadata on 
your server. In other words, it will push your public key to your new server, so
run the command below to do an initial login to your new server. You will need to
change the project and server name to the ones you used for your VM instance.
You may also be able to skip the <code>--zone</code> part of this command.

    gcloud compute ssh "elixirconf-www-01" \
      --project "elixirconf" \
      --zone "us-central1-a" 

### Set up SSH access

Until we set a domain for this machine, we can configure <code>~/.ssh/config</code>
for easy access and we must also tell <code>ssh</code> to use the 
<code>google_compute_engine</code> key since it has a non-standard name.

Edit your <code>~/.ssh/config</code> file and add 

    Host <shortname>
      HostName <host-IP>
      User <username>
      IdentityFile ~/.ssh/google_compute_engine

    Host <server-IP>
      HostName <server-IP>
      IdentityFile ~/.ssh/google_compute_engine

With this setup, you can run <code>ssh &lt;shortname></code> to connect
to the server. It's very convenient.

You will also need the <code>server-IP</code> version for deployment
later on since <code>eDeliver</code> will not connect unless <code>Host</code>
is an actual DNS name or an IP address.

### Update the VM instance

Depending on when you create your new VM, there may be updates ready for the machine.
FreeBSD makes it very easy to keep a machine up-to-date and secure. Simply run
the following on your machine after connecting via <code>ssh</code>.

    sudo freebsd-update fetch
    sudo freebsd-update install
    sudo shutdown -r now  # only required if an update was found

Note that the intances on GCE cannot be logged into using a password. This is the default setting.
Also, you cannot log into the server as <code>root</code>. However, <code>root</code> does
not have a password set by default, so the <code>sudo</code> commands above can be executed
in batch.

### Setup the Web Server

There are several apps that need to be installed for the new server to be a build host and
a web host. The differences between the two is that a web host needs <code>nginx</code> and <code>erlang</code>, 
but not <code>elixir</code>. And the build host needs <code>elixir</code>.

The scripts provided here install <code>elixir</code> and provide the script for <code>nginx</code>
installation, but requires it to be manually installed at the end. So, even though <code>elixir</code>
is not needed for a web host, the scripts here could still be used for that purpose without any change.

The server setup script prepares this host as a <code>build</code> and <code>web</code> server.
Run the command below:

    \curl -sSL https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/freebsd-setup.sh | bash 

This script installs several apps and also places some code in <code>/tmp</code> for you to run manually
as needed. The base installs should not take too long to run.

This script sets the user environment with <code>user-env.sh</code>, 
installs the base applications with  <code>base-installs.sh</code>, 
installs the web applications with <code>web-installs.sh</code>,
and installs and sets up the config files for nginx (but prompts the user that installation must be run manually).


### Customizing the Install

FreeBSD by default uses <code>sh</code> as a default shell. We need to change that to <code>bash</code>
to support <code>eDeliver</code>.

    # Update the shell for edeliver
    ./tmp/chg-shell-to-bash.sh
    exit # logout and log back in

### Install nginx

If this host is to be used as a <code>web</code> server, 
edit the install script first at <code>/tmp/nginx-setup.sh</code>
and set the <code>DOMAIN</code> variable for your project.

    # Edit DOMAIN to point to hostname
    DOMAIN=.ElixirConf.com

Then run the nginx setup script

    /tmp/nginx-setup.sh

Finally, feel free to review the <code>nginx</code> config file
with the command

    sudo vim /usr/local/etc/nginx/nginx.conf

If not rebooted yet, you can start <code>nginx</code> with

    sudo /usr/local/etc/rc.d/nginx start  

That's it for the remote server.

# Back to your local machine

You are now ready to update your Phoenix project by adding
Distillery and Edeliver deps to <code>mix.exs</code>.
Switch to your Phoenix project and edit <code>mix.exs</code>.

    # in defp deps add
    {:distillery, "~> 1.0" },
    {:edeliver, "~> 1.4.0"},

Also, add <code>:edeliver</code> to your list of applications in <code>mix.exs</code>.
It should look something like this:

    applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                   :phoenix_ecto, :postgrex, :edeliver]]

Now update your project

    mix deps.get

and create the Distillery release directory <code>rel</code>

    mix release.init

The default `.gitignore` file generated by Phoenix ignores the contents of the `priv/static`
directory, which means that when deploying your project, the contents of that directory must be
regenerated on the build machine. The default Phoenix method for doing this involves <code>brunch</code> and 
can be done inside a shell script, however Distillery offers a plugin API which allows us to execute Elixir
code as part of the release process, which is the approach we'll use below.

You can add that plugin to populate the <code>priv/static</code> directory during deployments
with the following script. Replace <code>&lt;ProjectName></code> with the name of your project
and run

    \curl -sSL https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/distillery-plugin.sh | bash -s <ProjectName>

This script will create the plugin script in `rel/plugins/static_plugin.exs`, and import it in `rel/config.exs`.

Now edit <code>rel/config.exs</code> and change the default environment to <code>:prod</code>

    # Change default build environment to :prod
    # This sets the default environment used by `mix release`
    default_environment: :prod

Add the newly added plugin to the `:prod` environment in `rel/config.exs`.
Remember to reference the name of your plugin instead of Elixirconf.

    environment :prod do
      plugin Elixirconf.PhoenixDigestTask
      set output_dir: "/app/deploys/elixirconf" # for v1.0
      ...

Remember to change the plugin name <code>ElixirConf</code> to the name of your plugin.
While you are editing this file, you can go ahead and add the <code>output_dir</code>
directory for the build machine. This is the directory where deploys are located.

### eDeliver

Next we setup for eDeliver by creating <code>.deliver</code> directory
and adding a <code>.deliver/config</code> file.

    # Add .deliver/config with settings changed for your project.
    APP="elixirconf"

    AUTO_VERSION=commit-count+branch-unless-master

    BUILD_CMD=mix
    RELEASE_CMD=mix
    USING_DISTILLERY=true

    BUILD_HOST="130.211.190.72"    # change this when DNS is set
                                   # Needs to be an actual DNS or IP 
                                   # address. Won't accept a .ssh/config 
                                   # alias
    BUILD_USER="jimfreeze"
    BUILD_AT="/app/builds/elixirconf"
    
    #STAGING_HOSTS=""
    #STAGING_USER="jimfreeze"

    PRODUCTION_HOSTS="130.211.190.72"    # deploy / production hosts separated by space
    PRODUCTION_USER="jimfreeze"          # local user at deploy hosts
    DELIVER_TO="/app/deploys/elixirconf" # deploy directory on production hosts
                                         # must agree with output_dir in rel/config.exs

    # For *Phoenix* projects, symlink prod.secret.exs to our tmp source
    pre_erlang_get_and_update_deps() {
      local _prod_secret_path="/app/builds/secret/prod.secret.exs"
      if [ "$TARGET_MIX_ENV" = "prod" ]; then
        __sync_remote "
          ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'
        "
      fi
    }

In <code>.deliver/config</code> you need to set your project name.
This is the same project name as set in <code>mix.exs</code>.

    APP="elixirconf"

I have also added <code>AUTO_VERSION</code> to my config file to
prevent having to specify it in scripts or from the command line.
There are various options to setting the version. See the docs
for more options.

    AUTO_VERSION=commit-count+branch-unless-master

The <code>BUILD_AT</code> directory is where your local mix project directory
gets recreated on the build machine.

Also, new with Distillery 1.0, you don't need <code>RELEASE_DIR</code>, but
you will need the <code>DELIVER_TO</code> directory. I made this match
the <code>output_dir</code> from <code>rel/config.exs</code>.

Finally, you need to copy your <code>config/prod.secret.exs</code> file to the
build server and specify that location in the 
<code>pre_erlang_get_and_update_deps()</code> part of the script.

I prefer to keep my build and deploy directories outside of a users directory,
and have chosen <code>/app</code> to place my builds and releases. 

Create directories on the build server as specified in .deliver/config if needed.

    ssh ecw "sudo mkdir /app; sudo chown jimfreeze:jimfreeze /app"

    # Create the needed directories on the build server and copy prod.secret.exs to the build server
    ssh ecw "mkdir -p /app/builds/secret"
    scp config/prod.secret.exs jimfreeze@ecw:/app/builds/secret


# Deploy!!!

Ok, not quite yet. We have a few more changes to make to our local
project before we can deploy.

Since we haven't setup the database in this deployment, you will
need to comment out the Repo in <code>lib/elixirconf.ex</code>.

    #  supervisor(Elixirconf.Repo, []),

AND, setup the production config file <code>config/prod.exs</code>,

    config :elixirconf, Elixirconf.Endpoint,
      #http: [port: {:system, "PORT"}],
      http: [ip: {127,0,0,1}, port: 4000],
      server: true,
      url: [host: "elixirconf.com", port: 80],
      version: Mix.Project.config[:version],
      cache_static_manifest: "priv/static/manifest.json"
    
Pay particular attention to 

      http: [ip: {127,0,0,1}, port: 4000],
      server: true,

Since we are running this server through <code>nginx</code>, the deployed Phoenix
server only needs to listen on the local machine -- and this coincides with how
we setup our proxy in <code>nginx.conf</code>. This will prevent outside access
to your Phoenix server on port 4000. Also note that instead of <code>host:</code>
the address is specified with <code>ip:</code>, AND that the address is a <code>tuple</code>.

Finally, note the line <code>server: true</code>. YOUR PHOENIX SERVER WILL NOT RUN
WITHOUT THIS AND IT IS NOT INCLUDED BY DEFAULT. Don't forget to add this line.
If you do, a telltale result is that you will see the server listening on random
ports yet not responding to any attempted connections.

Before deploying, make sure that your project files are up to date with
the Distillery and eDeliver configs checked into git.

Start the deploy process by building the release

    mix edeliver build release

Finish the deploy and restart the service in one command with

    mix edeliver deploy release to production --start-deploy

Add the --verbose flag if needed to debug any issues.

You can also skip the <code>--start-deploy</code> flag and manually start
and stop the server with the commands

    mix edeliver stop production
    mix edeliver start production
    mix edeliver restart production

### Deploy details

Now that you have verified that deployment works, you can setup a reboot cronjob
that starts up the web server should the server be rebooted. On the deployment
server, add the following to cron (with your appropriate changes)

    echo "@reboot /app/deploys/elixirconf/bin/elixirconf start" | crontab -

As you will find out, deployments start to enter the wild and wooly west at this point.
As you do multiple deployments, you will see that <code>mix edeliver build release</code>
will fail if multiple releases are present on the build machine unless 
the <code>RELEASE_VERSION</code> environment is set when mix is run.

You will also notice that if multiple releases exist on the local machine, that
<code>mix edeliver deploy release to production</code> will prompt for which
version to deploy to the deploy machine.

To keep things simple, and so deployments can run without human input, 
you can clear out releases on the local and remote machines.

Here is one possible script for auto deployment. The <code>ecw</code> is an ssh alias
for my build/deploy machine.

    #!/bin/sh
    # remove releases on the build server
    ssh ecw "rm -rf /tmp/releases; mv -f /app/deploys/elixirconf/releases /tmp; rm -rf /app/deploys/elixirconf/releases"
    # remove local releases
    rm .deliver/releases/*gz
    mix edeliver build release
    mix edeliver deploy release to production --start-deploy

# SSL Configuration

For SSL configuration of the website we are going to obtain a certificate from 
[Letsencrypt](https://letsencrypt.org/). Adding this certificate in
the standalone method used here means that we will need to stop the production
webserver. The process only takes a few seconds, so if you have your
new <code>nginx.conf</code> file ready, you can limit your downtime.

You will also need to configure DNS before setting up SSL. An "A" record
and a "CNAME" are required to complete SSL authentication.

    Type          Name                 Content
      A	       elixirconf.com          1.2.3.4
    CNAME	   www.elixirconf.co m	  elixirconf.com

If you are setting your DNS server for the first time, point your browser to 
your new domain to verify DNS is pointing to your new server.

On the web server, run the following to install the cert script

    sudo pkg install -y py27-certbot

And stop nginx so you can authenticate with the cert server.

    sudo /usr/local/etc/rc.d/nginx stop

And run the following script to automatically obtain your certs. Don't forget
to update is for your project.

    sudo certbot certonly  --standalone --rsa-key-size 4096 --email <me@email.com> -d <mydomain.com>

If all goes well, you should see output like

    IMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at
       /usr/local/etc/letsencrypt/live/elixirconf.com/fullchain.pem. Your
       cert will expire on 2017-03-14. To obtain a new or tweaked version
       of this certificate in the future, simply run certbot again. To
       non-interactively renew *all* of your certificates, run "certbot
       renew"

Update your <code>nginx.conf</code> file to be similar to


    load_module /usr/local/libexec/nginx/ngx_mail_module.so;
    load_module /usr/local/libexec/nginx/ngx_stream_module.so;
    worker_processes  1;
    
    events {
        worker_connections  256;
    }
    
    http {
      include            mime.types;
      default_type       application/octet-stream;
      sendfile           on;
      keepalive_timeout  65;
      #gzip               on;
      server {
        listen 80;
        server_name elixirconf.com;
        return 301 https://$server_name$request_uri;
      }
      server {
        listen       443 ssl;
        server_name  .elixirconf.com;
        ssl_certificate  /usr/local/etc/letsencrypt/live/elixirconf.com/fullchain.pem;
        ssl_certificate_key /usr/local/etc/letsencrypt/live/elixirconf.com/privkey.pem;
        location / {
          proxy_pass http://127.0.0.1:4000;
        }
      }
    }

and restart <code>nginx</code>

    sudo /usr/local/etc/rc.d/nginx start

With Letsencrypt, SSL certs only last a maximum of three months. According to the docs, it
is advised that you setup a cronjob to run twice a day to renew the certs. It won't hurt
to run the renew script before the certs expire, the request will just be ignored, but
Letsencrypt reserves the right to cancel SSL certs at anytime, so running a renew twice 
a day will minimize any downtime should the cert be recalled early.

Simply add to your root user cronjobs by running the following on the deploy machine.
The docs also request that you pick a random minute with which to run the cronjob.

    sudo su -
    crontab -e
    # add the following to root's cron
    14 11,23 * * * /usr/local/bin/certbot renew

One final step in the SSL configuration is to edit <code>config/prod.exs</code> to have Phoenix use the <code>https</code> schema
for URLs

    #url: [host: "elixirconf.com", port: 80],
    url: [host: "elixirconf.com", port: 443], # for ssl thru nginx

You can also go back now and edit <code>.deliver/config</code> and update the server
variables with your new DNS name.

    ...
    BUILD_HOST="elixirconf.com"
    ...
    PRODUCTION_HOSTS="elixirconf.com"
    ...

It's interesting to note that these simple steps allow the following URLs to be handled:

    http://elixirconf.com
    http://www.elixirconf.com
    https://elixirconf.com
    https://www.elixirconf.com

They all redirect to <code>https://elixirconf.com</code>.


