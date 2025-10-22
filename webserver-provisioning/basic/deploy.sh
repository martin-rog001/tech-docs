#!/bin/bash
# Simple deployment script

WEB_ROOT="/var/www/html"

echo "Deploying website..."

# Copy your files here
# cp -r /path/to/files/* $WEB_ROOT/

# Set permissions
chown -R www-data:www-data $WEB_ROOT
chmod -R 755 $WEB_ROOT

# Reload NGINX
nginx -t && systemctl reload nginx

echo "Deployment complete!"
