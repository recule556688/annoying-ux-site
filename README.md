# Annoying UX Site — Docker hosting

Serves the static HTML site with nginx, ready to put behind Nginx Proxy Manager (NPM).

## Quick start

On your server, copy this folder and run:

```bash
docker compose up -d --build
```

The site listens on **port 8080** on the host (`http://<server-ip>:8080`).

## Nginx Proxy Manager

### Option A — NPM on the same machine (host network / port mapping)

1. In NPM: **Hosts → Proxy Hosts → Add Proxy Host**
2. **Domain names**: your subdomain, e.g. `suffer.example.com`
3. **Scheme**: `http`
4. **Forward hostname / IP**: your server’s LAN IP (or `127.0.0.1` if NPM is on the same host)
5. **Forward port**: `8080`
6. Enable **SSL** (Let’s Encrypt) on the SSL tab if you want HTTPS

### Option B — NPM and this container on the same Docker network (recommended)

1. Find NPM’s network name:

   ```bash
   docker network ls
   ```

   Common names: `npm_default`, `nginxproxymanager_default`, or similar.

2. In `docker-compose.yml`, uncomment the `networks` section and set the correct external network name.

3. Recreate the stack:

   ```bash
   docker compose up -d
   ```

4. In NPM, add a Proxy Host:
   - **Forward hostname / IP**: `annoying-ux-site` (the service/container name)
   - **Forward port**: `80`
   - No host port mapping required; you can remove the `ports:` block if you only use the Docker network.

## Update the site

After editing `site/index.html` (or replacing it from `Annoying UX Site.html`):

```bash
docker compose up -d --build
```

## Commands

```bash
docker compose logs -f    # view logs
docker compose down     # stop and remove containers
docker compose ps       # status
```

## GitHub Actions deploy

Every push to `main` builds a Docker image, pushes it to GitHub Container Registry (GHCR), and deploys to your server over SSH.

### 1. Push this repo to GitHub

```bash
git init
git add .
git commit -m "Add Docker hosting and deploy workflow"
git remote add origin git@github.com:YOU/annoying-ux-site.git
git push -u origin main
```

### 2. One-time server setup

On your VPS (Docker and Docker Compose must already be installed):

```bash
git clone git@github.com:YOU/annoying-ux-site.git ~/annoying-ux-site
cd ~/annoying-ux-site
```

Allow the server to pull from GHCR (pick one):

- **Public package (simplest):** In GitHub → **Packages** → your container → **Package settings** → change visibility to **Public**. No `docker login` needed on the server.
- **Private package:** Create a PAT with `read:packages`, then on the server:
  ```bash
  echo YOUR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
  ```

### 3. GitHub repository secrets

In the repo: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Example | Required |
|--------|---------|----------|
| `SSH_HOST` | `203.0.113.10` or `myserver.example.com` | Yes |
| `SSH_USER` | `deploy` | Yes |
| `SSH_PRIVATE_KEY` | Contents of your deploy key / private key | Yes |
| `DEPLOY_PATH` | `/home/deploy/annoying-ux-site` | Yes |

If SSH runs on a non-default port, add `port:` under the deploy step in `.github/workflows/deploy.yml`.

The deploy user needs permission to run `docker compose` (usually membership in the `docker` group).

### 4. Deploy

Push to `main`, or run the workflow manually from **Actions → Build and Deploy → Run workflow**.

The workflow will:

1. Copy `Annoying UX Site.html` → `site/index.html`
2. Build and push `ghcr.io/<owner>/<repo>:latest`
3. SSH to your server, `docker compose pull`, and restart the container

Locally, `docker compose up -d --build` builds from source. On the server, CI sets `IMAGE=ghcr.io/<owner>/<repo>:latest` so compose pulls the pre-built image instead.
