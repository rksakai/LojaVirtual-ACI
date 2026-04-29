#!/bin/bash
set -e

echo "==> Iniciando Nginx..."
nginx -g "daemon off;" &

echo "==> Iniciando Gunicorn..."
cd /app
exec gunicorn \
    --bind 0.0.0.0:5000 \
    --workers 2 \
    --timeout 60 \
    --log-level info \
    app:app
