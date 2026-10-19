# Deploy analytics API on Alibaba Cloud ECS (Hong Kong)

Do **not** deploy from this PR automatically — run these steps on your ECS box when ready.

## What we need from you

| Item | Why |
|------|-----|
| ECS public IP + SSH access (key or password) | Install Docker, pull repo, start compose |
| Hong Kong region instance (recommended) | Lower latency for HK/Asia students |
| Domain name with A record → ECS IP | Let's Encrypt HTTPS |
| LLM API key | DashScope/Qwen on Alibaba, or any OpenAI-compatible base URL |
| Strong `JWT_SECRET` | Sign teacher + device tokens |
| Optional: Postgres password override | Replace defaults in `.env` |

## Security group (Alibaba console)

Open inbound TCP:

- `22` — SSH
- `80` — HTTP (Let's Encrypt + redirect)
- `443` — HTTPS

Keep `5432` (Postgres) **private** — only the Docker network should reach it.

## Steps

1. Create an Ubuntu 22.04 ECS in **cn-hongkong** (or `ap-southeast-1` if you prefer Singapore).
2. SSH in and install Docker + Compose plugin.
3. Clone this repo, then:
   ```bash
   cd server
   cp .env.example .env
   # edit .env: JWT_SECRET, POSTGRES_PASSWORD, LLM_API_KEY, LLM_BASE_URL, LLM_MODEL
   docker compose up -d --build
   ```
4. Health check: `curl http://$ECS_IP/api/health`
5. Register a teacher (API), mint a device token for the iOS app.
6. Point your domain A record at the ECS IP; issue a Let's Encrypt cert (certbot volume is wired in Compose). Enable the HTTPS server block in `nginx/`.
7. Cron a nightly `pg_dump` into `./backups` (folder is mounted).

## iOS app wiring

After the server is up:

- `analyticsServerBaseURL` = `https://YOUR_DOMAIN/api`
- `analyticsServerToken` = device token from step 5

The app queues answer events offline and retries; the teacher dashboard reads from the server and falls back to local analytics when the URL/token is empty or unreachable.

## LLM insight endpoint

- Set `LLM_API_KEY` + `LLM_BASE_URL` (DashScope OpenAI-compatible endpoint, or OpenAI).
- If the key is missing or the call fails, the API returns **rule-based** insights automatically.
