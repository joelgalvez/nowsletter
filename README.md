# Nowsletter

You need two parts for this:
1. The (web) server - (this project). Can run on a public vps or similar, if you want it to be public
2. The LLM server - (link). Needs to run on a private network that can't be called from the internet.

The LLM server runs another rails project that in turns calls llama-server on that computer.

The idea is that you got some computer in the closet that does the actual inference. This setup would have been a lot simpler if the webserver had direct access to llama-server, but I didn't want to expose my private home network, so instead i got this rather complicated setup: The LLM server calls the web server and creates a web socket and waits for updates.

The web server also runs postfix and waits for incoming email. Every place you subscribe to gets their own secret email inbox (secret-xxxxxx@email.com). Any email address to some other inbox is ignored. This way it's sort of sure who the email is from.


**How it works:**

1. You subscribe to newsletters using one unique email per venue: "secret-xxxxxx@email.com"
2. Action Mailbox receives the email and creates a `Letter` record
3. An external parser worker picks up the `LlmJob`, sends the letter text to an LLM, and posts the structured JSON back
4. The app creates `Event` records from the result
5. You check how it looks, change things maybe, maybe publish in the dashboard
6. Venue editors (the newsletter authors) do the same thing, if they want
7. The result is a calendar

---

## Requirements

- Ruby 3.4.5
- Node.js (for Tailwind CSS)
- SQLite 3

## Getting started

```bash
git clone <repo-url>
cd nowsletter
bin/setup
```

`bin/setup` installs dependencies, copies the example config files, and prepares the database. It then starts the dev server automatically.

If you want to set it up without starting the server:

```bash
bin/setup --skip-server
bin/dev   # start later
```

## Configuration

Copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `APP_NAME` | Yes | Displayed in the browser title and emails |
| `APP_HOST` | Yes | Hostname used for URL generation in mailers |
| `INITIAL_ADMIN_EMAIL` | Yes | Email address seeded as the first admin user |
| `DEFAULT_FROM_EMAIL` | Yes | From address for outgoing mail |
| `EMAIL_PREFIX_PATTERN` | Yes | Prefix that routes inbound mail to the correct venue (e.g. `secret-`) |
| `VENUE_EMAIL_DOMAIN` | Yes | Domain for venue inbound addresses (e.g. `id.example.com`) |
| `SMTP_ADDRESS` | Yes | SMTP server hostname |
| `SMTP_PORT` | Yes | SMTP port (typically `587`) |
| `SMTP_USER_NAME` | Yes | SMTP username |
| `SMTP_PASSWORD` | Yes | SMTP password |
| `RAILS_INBOUND_EMAIL_PASSWORD` | Yes | Shared secret between the Postfix relay and Action Mailbox |
| `PARSER_EMAIL` | No | Email of the parser worker user (created on `db:seed`) |
| `PARSER_PASSWORD` | No | Password for the parser worker user |
| `SECRET_KEY_BASE` | No | Rails secret key base (auto-generated in development) |
| `TIME_ZONE` | No | IANA timezone name, e.g. `Europe/Amsterdam` (default: `UTC`) |
| `PLAUSIBLE_SCRIPT_URL` | No | Plausible analytics script URL |
| `PLAUSIBLE_API_URL` | No | Plausible analytics API URL |

After setting up env vars, seed the database to create the admin user:

```bash
bin/rails db:seed
```

Log in at `/` with the `INITIAL_ADMIN_EMAIL` address. Use **Forgot password** to set a password on first login.

## Adding a custom environment

To deploy a second instance (e.g. a tenant or staging), add a Rails environment:

```bash
echo 'require_relative "production"' > config/environments/myenv.rb
```

Then add a `myenv:` section to `config/database.yml`, `config/cache.yml`, `config/cable.yml`, and `config/recurring.yml` — see the comments at the bottom of each `*.example.yml` for the pattern.

## Deployment

This app deploys with [Kamal](https://kamal-deploy.org/) and requires a Postfix accessory for inbound email. See [`docs/deploy-instructions.md`](docs/deploy-instructions.md) for the full guide.

## Running tests

```bash
bin/rails test
```
