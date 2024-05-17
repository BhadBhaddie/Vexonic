#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install Nginx and FFmpeg
sudo apt install -y nginx libnginx-mod-rtmp ffmpeg

# Configure Nginx with RTMP and HLS
cat <<EOF | sudo tee /etc/nginx/nginx.conf
worker_processes auto;
events {
    worker_connections 1024;
}
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;
            exec ffmpeg -i rtmp://localhost/live/\$name -c:v libx264 -crf 18 -preset veryfast -c:a aac -b:a 128k -f hls -hls_time 4 -hls_playlist_type event /var/www/live/\$name.m3u8;
        }
    }
}
http {
    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
            try_files \$uri \$uri/ =404;
        }

        location /live {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            alias /var/www/live;
            add_header Cache-Control no-cache;
        }
    }
}
EOF

# Create the directory for HLS streams
sudo mkdir -p /var/www/live
sudo chown -R www-data:www-data /var/www/live

# Restart Nginx to apply the new configuration
sudo systemctl restart nginx

# Install Let's Encrypt certbot (optional for HTTPS)
sudo apt install -y certbot python3-certbot-nginx

# Create a basic web interface
cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Live Stream</title>
    <link href="https://vjs.zencdn.net/7.11.4/video-js.css" rel="stylesheet" />
</head>
<body>
    <h1>Live Streams</h1>
    <p>Replace <strong>streamname</strong> with your stream key from OBS.</p>
    <video-js id="my-video" class="vjs-default-skin" controls preload="auto" width="640" height="264" data-setup='{}'>
        <source src="http://192.168.56.101/live/streamname.m3u8" type="application/x-mpegURL">
    </video-js>
    <script src="https://vjs.zencdn.net/7.11.4/video.js"></script>
</body>
</html>
EOF

# Instructions for the user
echo "Setup complete!"
echo "To start streaming, set your OBS stream URL to: rtmp://your_server_ip/live and choose a stream key."
echo "Access the web interface at: http://your_server_ip"
echo "For HTTPS, run: sudo certbot --nginx -d your_domain"

# Note: Replace 'your_server_ip' with your actual server IP address
