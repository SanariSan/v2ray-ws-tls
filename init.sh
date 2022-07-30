#!/bin/bash

bash /conf/default.conf.sh > /etc/nginx/conf.d/default.conf
echo /etc/nginx/conf.d/default.conf
cat /etc/nginx/conf.d/default.conf

if [[ ! -d /wwwroot/test ]]; then
    mkdir -p /wwwroot/test
fi

echo "Test page" > /wwwroot/test/index.html

rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'