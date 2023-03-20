#!/bin/bash

sudo apt update -y
sudo apt -y install nginx

touch nginx.conf

cat > nginx.conf <<EOL
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include            mime.types;
    default_type       application/octet-stream;
    keepalive_timeout  65;
    sendfile           on;
    gzip               on;

    server {
        listen             ${port};

        error_page         500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        location / {
            proxy_pass http://application;
        }
    }

    upstream application {
        %{ for server in servers ~}
        server ${server};
        %{ endfor ~}
    }
}

EOL

cp /etc/nginx/nginx.conf /etc/nginx/nginx.backup.conf

cp -f nginx.conf /etc/nginx/nginx.conf

sudo systemctl restart nginx

sleep 5;

HTTP_STATUS_CODE=$(curl -I -f http://localhost | head -n 1 | cut -d$' ' -f2)

until [[ "$HTTP_STATUS_CODE" != "200" ]]; do
    sleep 1;
done
