#!/bin/bash

echo "<html><body>" >/usr/share/nginx/html/index.html
echo "<h2>Pod: $POD_NAME</h2>\n<h2>Node: $NODE_NAME</h2><h2>Namespace: $POD_NAMESPACE</h2>\n<h2>IP: $POD_IP</h2>" >>/usr/share/nginx/html/index.html
echo "</body></html>" >>/usr/share/nginx/html/index.html

# Refer: https://github.com/nginxinc/docker-nginx/blob/master/Dockerfile-debian.template#L109
nginx -g 'daemon off;'
