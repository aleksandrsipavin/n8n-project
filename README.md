# n8n + Postgres behind Traefik (local domain, self‑signed TLS)

This repo brings up a production‑like n8n on Docker Compose:

- Traefik reverse proxy with **HTTP→HTTPS** redirect
- Self‑signed TLS certificate for `https://$SUBDOMAIN.$DOMAIN_NAME`
- n8n with persistent volume
- Postgres with persistent volume
- Secrets via **Docker secrets** (`*_FILE` env pattern) — no passwords in compose

Works fully offline on a LAN using a local domain (e.g. `n8n-node.local`). For a public domain + Let’s Encrypt, see **Switch to real HTTPS (ACME)**.

---

## 1) Prereqs

- Docker and Docker Compose v2

```bash
sudo bash ./scripts/docker_prereq.sh
sudo bash ./scripts/docker_prereq2.sh
```

- Shell with `openssl`
- Local name resolution for `${SUBDOMAIN}.${DOMAIN_NAME}` (add to `/etc/hosts` or your LAN DNS)

Example `/etc/hosts` entry (replace IP with your host):
```
192.168.1.50  n8n-node.local
```

---

## 2) Configure

Copy the env template and edit non‑secrets:

```bash
cp .env.example .env
$EDITOR .env
```

`.env` controls: domain/hostname and timezone.

---

## 3) Bootstrap (secrets + certs)

This creates Docker secrets and a self‑signed certificate:

```bash
./scripts/bootstrap.sh
```

It writes to `secrets/` and `certs/` and won’t overwrite existing files.

> To get a trusted padlock locally, consider `mkcert` instead of a generic self‑signed cert (see notes inside `bootstrap.sh`).

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

## 6) Switch to real HTTPS (ACME / Let’s Encrypt)

When you have a public DNS name pointing at this host:

1. Edit `compose.yaml`  
   - In **traefik**: enable ACME flags (see commented lines), remove the file‑provider TLS if desired.  
   - In **n8n** labels: set router entrypoint to `websecure`, `tls=true`, and add `certresolver`.  
2. Update `.env` with the real domain (e.g. `SUBDOMAIN=n8n`, `DOMAIN_NAME=example.com`).  
3. Restart:
   ```bash
   docker compose up -d
   ```

For private/internal domains, you can also use DNS‑01 (provider API), or keep self‑signed/mkcert.

---

## 7) Troubleshooting

- **Browser warns about certificate**: expected with self‑signed. Trust the cert on the client, or use `mkcert`.  
- **n8n can’t connect to DB**: ensure `DB_POSTGRESDB_*_FILE` secrets exist and Postgres is healthy (`pg_isready`).  
- **Traefik 404**: verify `Host()` matches `SUBDOMAIN.DOMAIN_NAME` exactly and your client resolves it to the host IP.  
- **Credentials lost after restart**: ensure the `N8N_ENCRYPTION_KEY` secret stays the same (don’t regenerate).  
- **Ports in use**: make sure nothing else is bound to `80/443` on the host.

---

## Security notes

- Secrets live in `./secrets/` (git‑ignored) and are consumed via Docker secrets (`*_FILE` env).  
- Volumes persist in Docker managed storage (`n8n_data`, `pgdata`).  
- Traefik dashboard is **disabled** by default; enable only on trusted networks.

---

## License

MIT
