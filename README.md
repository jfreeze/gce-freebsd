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

# Choices

The setup includes instructions on creating a 
FreeBSD instance on [Google Compute Engine](https://cloud.google.com/compute/),
setting up DNS using [DNSimple](https://dnsimple.com),
free SSL cert generation using [Letsencrypt](https://letsencrypt.org/) for https transport,
and [Nginx](https://nginx.org/en/) to handle web services.

# Overview

 1. Create a GCE instance
 1. Configure nginx
 1. Install and configure distillery
 1. Install and configure edeliver
 1. Deploy Phoenix app to web server
 1. Create SSL cert from Letsencrypt
 1. Configure nginx for SSL

# Getting Started

The first order of business is to create a VM instance on the Google Compute Engine cloud service.

## Create a GCE Project

If you don't already have a project, you will need to create a project to run your
Google Compute Engine VM's under. Google allows up to five projects.

This is a seldom done task and is easy enough to do that I am not providing
and console oriented way of creating a project. 

Simply open up your [GCE console](https://console.cloud.google.com/iam-admin/iam/)
in a web browser, click the three horizontal bars (the hamburger menu) in the upper
left of the page, select <code>IAM &amp; Admin</code>, then click on 
<code>All Projects</code>. You should see a <code>+ CREATE PROJECT</code> 
link to create a new project.

## Creating the VM Network 

Delete the default network (if new project)
	# delete default firewall rules
	./gcloud-compute-firewall-rules-delete.sh elixirconf

	# delete default network
	gcloud compute networks delete "default" \
  		--project elixirconf

Create a Network
	./gcloud-compute-network-create.sh elixirconf elixirconf-net

Create firewall rules
	./gcloud-compute-firewall-rules-create.sh elixirconf elixirconf-net

Create a Server
	./gcloud-compute-instance-create.sh elixirconf elixirconf-www-01 elixirconf-net

Connect to the new VM Instance (Your web server)
  # Set a static IP if desired, by clicking on the instance
  # name, click edit at the top of the page,
  # change from ephemeral IP to static IP (create a name)
  # save the changes

  # connect with gcloud to update project ssh metadata
  gcloud compute ssh "elixirconf-www-01" \
    --project "elixirconf" \
    --zone "us-central1-a" 

  # Until we set a domain for this machine, you can configure ~/.ssh/config
  # edit ~/.ssh/config and add 

  Host ecw
    HostName <host-IP>
    User jimfreeze
    IdentityFile ~/.ssh/google_compute_engine

  ssh ecw

  # Update the VM instance
  sudo freebsd-update fetch
  sudo freebsd-update install
  sudo shutdown -r now  # only required if an update was found

  # Run the gce-freebsd setup script to prepare for Phoenix webserver
  \curl -sSL https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/freebsd-setup.sh | bash 

  # Update the shell for edeliver
  ./tmp/chg-shell-to-bash.sh
  exit # logout and log back in

  # If not rebooted yet, start nginx
  sudo /usr/local/etc/rc.d/nginx start  

# Back to your local machine
  
  # Add Distillery and Edeliver deps to mix.exs

  {:distillery, "~> 1.0" },
  {:edeliver, "~> 1.4.0"},

  # Also, add :edeliver to your apps in mix.exs

        applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :postgrex, :edeliver]]

  mix deps.get

  # Create the Distillery release directory

  mix release.init

  # and add a plugin to populate the priv/ directory during deployments.
  # Replace <ProjectName> with the name of your project.
  \curl -sSL https://raw.githubusercontent.com/jfreeze/gce-freebsd/master/distillery-plugin.sh | bash -s <ProjectName>

  # Edit rel/config.exs
  # Change default build to :prod
      # This sets the default environment used by `mix release`
      default_environment: :prod

  # Add the newly added plugin to the :prod environment in rel/config.exs
  # Remember to reference the name of your plugin instead of Elixirconf.
    environment :prod do
      set plugins: [Elixirconf.PhoenixDigestTask]
      ...

  # Create .deliver/ directory
  # Add .deliver/config with settings changed for your project.

	APP="elixirconf"

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

	# For *Phoenix* projects, symlink prod.secret.exs to our tmp source
	pre_erlang_get_and_update_deps() {
	  local _prod_secret_path="/app/builds/secret/prod.secret.exs"
	  if [ "$TARGET_MIX_ENV" = "prod" ]; then
	    __sync_remote "
	      ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'
	    "
	  fi
	}

  # Create directories on the build server as specified in .deliver/config if needed.
  ssh ecw "sudo mkdir /app; sudo chown jimfreeze:jimfreeze /app"

  # Create the needed directories on the build server and copy prod.secret.exs to the build server
  ssh ecw "mkdir -p /app/builds/secret"
  scp config/prod.secret.exs jimfreeze@ecw:/app/builds/secret

  # Deploy!!!
  # Before deploying, make sure that your project file is up to date with
    the Distillery and eDeliver configs checked into git.

  # ALSO, since we haven't setup the database in this deployment, you will
    need to comment out the Repo in lib/elixirconf.ex

     #      supervisor(Elixirconf.Repo, []),

  AND, setup the production config
config :elixirconf, Elixirconf.Endpoint,
  # http: [port: {:system, "PORT"}],
  http: [host: "127.0.0.1", port: 4000],


  # Start the deploy process with

/app/build/elixirconf/rel/elixirconf/releases/0.0.1+22

  	git rev-list HEAD --count
	RELEASE_VERSION="0.0.1+19" mix edeliver build release --auto-version=commit-count

    # remove builds on the build server
ssh ecw "mv -f /app/deploys/elixirconf/releases /tmp; rm -rf /app/deploys/elixirconf/releases"
rm .deliver/releases/*gz
# version is set in .deliver/config
mix edeliver build release

  Add the --verbose flag if needed to debug any issues.

  Finish the deploy with


mix edeliver deploy release to production --start-deploy

    mix edeliver stop production
    mix edeliver start production
    mix edeliver restart production


------
This script sets the user environment found in the <code>user-env.sh</code>, 
installs the base applications in <code>base-installs.sh</code>, 
installs the web applications in <code>web-installs.sh</code>,
sets up the config files for nginx (but prompts the user that installation must be run manually).

Once run, the server is ready for web application deployment.


Example how to create a project and VM instance
