#!/bin/bash
set -e

# Support Render custom PORT
if [ -n "$PORT" ]; then
    sed -i "s/80/$PORT/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf 2>/dev/null || true
fi

# Determine DB variables with robust fallbacks
DB_HOST_VAL="${DB_SERVER:-${DB_HOST:-127.0.0.1}}"
DB_PORT_VAL="${DB_PORT:-3306}"
DB_NAME_VAL="${DB_NAME:-defaultdb}"
DB_USER_VAL="${DB_USER:-avnadmin}"
DB_PASSWD_VAL="${DB_PASSWD:-${DB_PASSWORD:-}}"
DB_PREFIX_VAL="${DB_PREFIX:-ps_}"

mkdir -p /var/www/html/app/config

# Always create app/config/parameters.php with clean parameters
cat <<EOF > /var/www/html/app/config/parameters.php
<?php return array (
  'parameters' => 
  array (
    'database_host' => '$DB_HOST_VAL',
    'database_port' => '$DB_PORT_VAL',
    'database_name' => '$DB_NAME_VAL',
    'database_user' => '$DB_USER_VAL',
    'database_password' => '$DB_PASSWD_VAL',
    'database_prefix' => '$DB_PREFIX_VAL',
    'database_engine' => 'InnoDB',
    'mailer_transport' => 'smtp',
    'mailer_host' => '127.0.0.1',
    'mailer_user' => NULL,
    'mailer_password' => NULL,
    'secret' => '${PS_SECRET:-sA9YOT35YaM0n0j6yf9M5q0uwkhap5uzoUgv08sucz9KSRFVUqnGA88mixpazEoR}',
    'ps_caching' => 'CacheMemcache',
    'ps_cache_enable' => false,
    'ps_creation_date' => '2026-09-18',
    'locale' => 'en-US',
    'cookie_key' => '${PS_COOKIE_KEY:-QRHUqnWz2G24eJSKH2mvBvyGcMzNOtTDD6xeEVaDSyjYu0NSCPJjsbyMsZRJrTjz}',
    'cookie_iv' => '${PS_COOKIE_IV:-vpU6nGpa1hgRqEmCiNcjp4SaeqwACd7J}',
    'use_debug_toolbar' => false,
    'new_cookie_key' => '${PS_NEW_COOKIE_KEY:-def00000c0df3d7638a53f413b1766af06a31724e35d429f4d00fc1cf3823318718ed6d2e3c4a74dda60660cc3bca15917e352bac83157fc33d15666e55cd140712ab208}',
  ),
);
EOF

# Support enabling Debug Mode via environment variable PS_DEV_MODE=true
if [ "$PS_DEV_MODE" = "true" ] || [ "$PS_DEV_MODE" = "1" ]; then
    cat <<'EOF' > /var/www/html/config/defines_custom.inc.php
<?php
define('_PS_MODE_DEV_', true);
EOF
else
    rm -f /var/www/html/config/defines_custom.inc.php
fi

# Clear stale Symfony/PrestaShop cache on container start
rm -rf /var/www/html/var/cache/* 2>/dev/null || true

# Ensure cache/log/img/upload directories exist and have write permissions
mkdir -p /var/www/html/var/cache /var/www/html/var/logs /var/www/html/img /var/www/html/upload
chown -R www-data:www-data /var/www/html/var /var/www/html/app/config /var/www/html/img /var/www/html/upload 2>/dev/null || true
chmod -R 775 /var/www/html/var /var/www/html/app/config /var/www/html/img /var/www/html/upload 2>/dev/null || true

exec "$@"
