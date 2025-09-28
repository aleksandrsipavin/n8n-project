#!/usr/bin/env bash
set -euo pipefail

# Config (matches compose healthcheck defaults)
DB_USER_DEFAULT="n8n"
DB_NAME_DEFAULT="n8n"
HOSTNAME_DEFAULT="${SUBDOMAIN:-n8n-node}.${DOMAIN_NAME:-local}"

mkdir -p secrets certs local-files

# 1) Secrets (create if missing)
[[ -f secrets/postgres_user.txt ]]      || echo "${DB_USER_DEFAULT}" > secrets/postgres_user.txt
[[ -f secrets/postgres_password.txt ]]  || openssl rand -base64 24 > secrets/postgres_password.txt
[[ -f secrets/postgres_db.txt ]]        || echo "${DB_NAME_DEFAULT}" > secrets/postgres_db.txt
[[ -f secrets/n8n_encryption_key.txt ]] || openssl rand -base64 24 > secrets/n8n_encryption_key.txt
# For ACME (public DNS) you can add:
# [[ -f secrets/acme_email.txt ]] || echo "you@example.com" > secrets/acme_email.txt

# 2) Self-signed cert (use mkcert for trusted local CA if you prefer)
CRT="certs/n8n.crt"
KEY="certs/n8n.key"
if [[ ! -f "$CRT" || ! -f "$KEY" ]]; then
  echo "Generating self-signed cert for CN=${HOSTNAME_DEFAULT}"
  openssl req -x509 -nodes -newkey rsa:2048 -days 825     -keyout "$KEY" -out "$CRT"     -subj "/CN=${HOSTNAME_DEFAULT}"     -addext "subjectAltName=DNS:${HOSTNAME_DEFAULT}"
fi

echo "Done. Review .env, ensure DNS/hosts points ${HOSTNAME_DEFAULT} to this host, then run:"
echo "  docker compose up -d"
