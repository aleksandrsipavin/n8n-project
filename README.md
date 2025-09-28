# Small project helping deploy n8n + Postgres behind Traefik on local infra

This repo brings up a production‑like n8n on Docker Compose:

- Traefik reverse proxy with **HTTP→HTTPS** redirect
- Self‑signed TLS certificate for `https://$SUBDOMAIN.$DOMAIN_NAME`
- n8n with persistent volume
- Postgres with persistent volume
- Secrets via **Docker secrets** (`*_FILE` env pattern) — no passwords in compose

For a public domain + Let’s Encrypt, better read the n8n manual).

---

## 1) Prereqs

- Docker and Docker Compose

```bash
sudo bash ./scripts/docker_prereq.sh #removes conflicting packages and installs docker components
sudo bash ./scripts/docker_prereq2.sh #adds a user to group 
```

- Shell with `openssl`
- On web client side name resolution for `${SUBDOMAIN}.${DOMAIN_NAME}` required

---

## 2) Configure

Copy the env template and edit non‑secrets:

```bash
cp .env.example .env
nano .env
```

`.env` controls: domain/hostname and timezone.

---

## 3) Bootstrap (secrets + certs)

This creates Docker secrets and a self‑signed certificate:

```bash
./scripts/bootstrap.sh
```

It writes to `secrets/` and `certs/` and won’t overwrite existing files.

---

## 4) Bring it up

```bash
docker compose up -d
docker compose ps
```

First launch checks:

```bash
docker compose logs -f postgres | sed -n '1,120p'
docker compose logs -f n8n | sed -n '1,200p'
```

Open **https://$SUBDOMAIN.$DOMAIN_NAME** (e.g. https://n8n-node.local) and complete n8n’s first‑run setup.

---

## 5) Common operations

Stop / Start:
```bash
docker compose stop
docker compose start
```

Update images:
```bash
docker compose pull
docker compose up -d
```

Backup Postgres (logical dump):
```bash
docker compose exec -T postgres   pg_dump -U n8n -d n8n > backup_$(date +%F).sql
```

Restore (destructive):
```bash
docker compose exec -T postgres   psql -U n8n -d n8n < backup_YYYY-MM-DD.sql
```
---

## Security notes

- Secrets live in `./secrets/` (git‑ignored) and are consumed via Docker secrets (`*_FILE` env).  
- Volumes persist in Docker managed storage (`n8n_data`, `pgdata`).  
- Traefik dashboard is **disabled** by default.
