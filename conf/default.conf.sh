#!/bin/bash
cat <<EOF
server {
    listen 80;
    listen [::]:80;

    root /wwwroot;

    location / {
        return 500;
    }
    
    location /test {
        root /wwwroot;
    }
}
EOF