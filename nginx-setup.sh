#!/bin/sh 

DOMAIN=.ElixirConf.com

echo
echo "*** Setting nginx.conf with domain ***"
echo "    ${DOMAIN}"
echo "    /usr/local/etc/nginx/nginx.conf"
echo "***"

if [ -f "/usr/local/etc/nginx/nginx.conf.orig" ]
then
else
	 sudo mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.orig
fi

cat << EOF > /tmp/nginx.conf 
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
    gzip               on;

    server {
      server_name  ${DOMAIN};
      location / {
        proxy_pass http://127.0.0.1:4000;
      }
    }
}
EOF
sudo mv /tmp/nginx.conf /usr/local/etc/nginx/nginx.conf 

if grep -Fxq "nginx_enable=YES" /etc/rc.conf
then
else
	sudo sh -c "echo \"nginx_enable=YES\" >> /etc/rc.conf"
fi

