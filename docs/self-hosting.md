# Self-Hosting Guide

This guide is for running Nowsletter on your own server using docker.

---

## What you're setting up

Two parts:

1. **Web server** (this project) — handles the website, inbound email, and event publishing
2. **LLM parser** — a separate app that runs on a private machine (e.g. a computer at home) and does the AI inference. It reaches out to the web server — you don't need to expose your private network.

---

## Requirements

- A VPS with root SSH access
- Docker and Docker Compose installed on the server ([install guide](https://docs.docker.com/engine/install/ubuntu/))
- A domain name you control
- An SMTP provider for outgoing email (AWS SES, Mailgun, Postmark, etc.)
- **Port 25 open for incoming traffic** on your server

Usually port 25 **outgoing** is blocked. That's okay, you only need incoming email on your server. Outgoing email is sent by SMTP (by some other provider).

---

## 1. DNS

Add these records at your DNS provider:

```
app.example.com.    A    <your-server-ip>
inbox.example.com.  A    <your-server-ip>
inbox.example.com.  MX   10 inbox.example.com.
```

- `app.example.com` — the website
- `inbox.example.com` — where newsletters get emailed (MX points inbound mail here)

DNS must resolve before you deploy — Caddy needs it to issue an SSL certificate.

---

## 2. Set up the server

SSH into your server and clone the repo:

```bash
ssh root@<your-server-ip>
git clone https://github.com/joelgalvez/nowsletter
cd nowsletter
```

---

## 3. Configure

Copy the example env file:

```bash
cp .env.example .env
```

Edit `.env`


## 4. Deploy

Install docker if you havent already, then:

```bash
docker compose up -d --build
```

This builds the app image, starts all containers, runs database setup, and obtains an SSL certificate automatically. Takes a few minutes the first time.

---

## 5. Log in

Go to `https://app.example.com` and click **Sign in** in the menu, then **Forgot password** for `you@example.com` to set your password on first login.

---

## 6. Connect the LLM parser

The LLM parser is a separate project. Once it's running, point it at `https://app.example.com` and give it the `PARSER_EMAIL` and `PARSER_PASSWORD` you set above. Refer to the LLM server repo for setup instructions.

---

## Useful commands

```bash
# View logs
docker compose logs -f app
docker compose logs -f postfix

# Rails console
docker compose exec app bin/rails console

# Update to latest version
git pull
docker compose up -d --build
```

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| SSL certificate fails on first start | DNS not resolving yet — wait a few minutes and restart with `docker compose restart caddy` |
| Mail arrives but app doesn't process it | `RAILS_INBOUND_EMAIL_PASSWORD` mismatch — must be identical in `.env` and the Postfix container |
| App starts but emails aren't sent | Check SMTP credentials in `.env` and that your provider allows the `DEFAULT_FROM_EMAIL` domain |
| `SECRET_KEY_BASE` error | Make sure it's set in `.env` — generate with `openssl rand -hex 64` |
