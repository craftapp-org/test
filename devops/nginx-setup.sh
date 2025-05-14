#!/bin/bash

# Arguments
project_name="$1"   # e.g., "Shop App"
email="$2"          # Email for Certbot SSL
server_ip="$3"      # Your server IP (must already have DNS configured)
sld="$4"            # e.g., "yourdomain" (without TLD)
tld="$5"            # e.g., "com"
frontend_port="$6"  # Frontend port (e.g., 3000)
backend_port="$7"   # Backend port (e.g., 8000)

# Sanitize project name to form subdomain
sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//'
}
host=$(sanitize_name "$project_name")
domain="${host}.${sld}.${tld}"

echo "➡ Configuring domain: $domain (assuming DNS is already set up)"

# Step 1: Create NGINX config
nginx_config="/etc/nginx/sites-available/$host"
sudo tee "$nginx_config" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    ssl_certificate /etc/letsencrypt/live/${sld}.${tld}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${sld}.${tld}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    location / {
        proxy_pass http://localhost:$frontend_port/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location /api/ {
        proxy_pass http://localhost:$backend_port/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Step 2: Enable the NGINX config
sudo ln -sf "$nginx_config" "/etc/nginx/sites-enabled/$host"
sudo nginx -t && sudo systemctl reload nginx
if [ $? -ne 0 ]; then
  echo "❌ NGINX configuration test failed. Aborting."
  exit 1
fi

# Step 3: Issue SSL certificate (if needed)
echo "🔐 Issuing SSL certificate for $domain..."
sudo certbot --nginx -d "$domain" --non-interactive --agree-tos -m "$email"

echo "✅ Deployment complete: https://$domain"
