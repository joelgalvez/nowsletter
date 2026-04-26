(This guide hasn't been tested yet, so steps might be missing/wrong.)

# Deploy instructions

End-to-end guide for setting up a new environment (e.g. `dev`, `staging`) with Kamal, including the Postfix mail relay. 


## Prerequisites

- Server with SSH root access. Docker installed by Kamal if missing
- DNS under your control for the app domain and mail domain
- `KAMAL_REGISTRY_PASSWORD` exported in your shell (Docker Hub token)
- A Docker Hub account (free) for storing the built image

## 1. DNS

Two records:

```
ENVNAME.yourdomain.com.      A    <server-ip>
inbox.yourdomain.com.           MX   10 <server-hostname-or-A-record>
```

MX target must be a hostname (not an IP). Let's Encrypt requires the A record to resolve *before* the first deploy.

## 2. Rails environment

### `config/environments/ENVNAME.rb`

```bash
echo 'require_relative "production"' > config/environments/ENVNAME.rb
```

### `config/database.yml` — add a section

```yaml
ENVNAME:
  primary:
    <<: *default
    database: storage/ENVNAME.sqlite3
  cache:
    <<: *default
    database: storage/ENVNAME_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/ENVNAME_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/ENVNAME_cable.sqlite3
    migrations_paths: db/cable_migrate
```

### `config/recurring.yml` — add a section

```yaml
ENVNAME:
  strip_pulled_letters:
    class: StripPulledLettersJob
    schedule: every 10 seconds
```

### `config/cache.yml` and `config/cable.yml`

Add sections if needed (staging inherits from production with `<<: *production`).

## 3. Credentials

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment ENVNAME
```

Creates `config/credentials/ENVNAME.key` and `config/credentials/ENVNAME.yml.enc`.

Minimum contents:

```yaml
smtp:
  address: smtp.example.com
  port: 587
  user_name: your@email.com
  password: your-smtp-password

action_mailbox:
  ingress_password: <long-random-string>

parser:
  email: whattever@parser-email.com
  password: some-password

```

**Back up `config/credentials/ENVNAME.key`** — not in git.

## 4. Kamal config

### `.env.ENVNAME` (gitignored)

```
RAILS_INBOUND_EMAIL_PASSWORD=<same value as credentials.action_mailbox.ingress_password>
```

### `.kamal/secrets.ENVNAME`

```bash
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY=$(cat config/credentials/ENVNAME.key)
RAILS_INBOUND_EMAIL_PASSWORD=$(grep '^RAILS_INBOUND_EMAIL_PASSWORD=' .env.ENVNAME | cut -d= -f2-)
```

### `config/deploy.ENVNAME.yml`

```yaml
service: APPNAME-ENVNAME
image: DOCKERHUB_ACCOUNT/APPNAME-ENVNAME

servers:
  web:
    - SERVER_IP

proxy:
  ssl: true
  host: ENVNAME.yourdomain.com

registry:
  username: DOCKERHUB_ACCOUNT
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true
    RAILS_ENV: ENVNAME
    APP_HOST: ENVNAME.yourdomain.com
    INITIAL_ADMIN_EMAIL: your@admin-email.com
    DEFAULT_FROM_EMAIL: from@yourdomain.com
    EMAIL_PREFIX_PATTERN: secret-
    VENUE_EMAIL_DOMAIN: id.yourdomain.com
    PLAUSIBLE_SCRIPT_URL: ""
    PLAUSIBLE_API_URL: ""

accessories:
  postfix:
    image: DOCKERHUB_ACCOUNT/APPNAME-postfix
    host: SERVER_IP
    port: "25:25"
    env:
      clear:
        MAIL_DOMAIN: id.yourdomain.com
        APP_DOMAIN: ENVNAME.yourdomain.com
      secret:
        - RAILS_INBOUND_EMAIL_PASSWORD

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole"

volumes:
  - "APPNAME_ENVNAME_storage:/rails/storage"
  - "APPNAME_ENVNAME_cached_images:/rails/public/cached_images"

asset_path: /rails/public/assets

builder:
  arch: amd64
  local: false
  local: true  # or: remote: ssh://user@build-server for a faster remote build
  args:
    RUBY_VERSION: 3.4.5
  secrets:
    - RAILS_MASTER_KEY
    - KAMAL_REGISTRY_PASSWORD
```



## 6. Build and push the Postfix image

```bash
docker buildx build --platform linux/amd64 -t DOCKERHUB_ACCOUNT/APPNAME-postfix --push docker/postfix/
```

`--platform linux/amd64` is required from an ARM Mac. Only repeat when `Dockerfile` or `entrypoint.sh` change — config is injected at runtime.

## 7. Deploy

```bash
bin/kamal setup -d ENVNAME        # first time only
bin/kamal deploy -d ENVNAME
```

Builds and pushes the Rails image, rolls the container, runs `db:prepare` + `db:seed`, registers with kamal-proxy for SSL.

## 8. Boot Postfix

```bash
bin/kamal accessory boot postfix -d ENVNAME
```

## 9. Verify

**App:**
```bash
curl https://ENVNAME.yourdomain.com/up
bin/kamal app logs -d ENVNAME
bin/kamal console -d ENVNAME
```

**Postfix:**
```bash
# on server
ss -tlnp | grep :25
bin/kamal accessory logs postfix -d ENVNAME

# from laptop
telnet <server-ip> 25     # should show "220 ... ESMTP Postfix"
```

**End-to-end:** send mail to `<prefix><venue-code>@id.yourdomain.com`. Logs should show `status=sent (delivered via webhook service)`. Then `ActionMailbox::InboundEmail.last` in Rails console.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `exec format error` in Postfix logs | Wrong arch — rebuild with `--platform linux/amd64`. |
| `RAILS_INBOUND_EMAIL_PASSWORD is required` | `.env.ENVNAME` missing/empty. Check `bin/kamal secrets print -d ENVNAME \| grep INBOUND`. |
| :25 hangs (no banner) | Host postfix conflict, or smtpd dying silently. `systemctl stop postfix`; check accessory logs. |
| :25 refused externally | Cloud firewall blocking inbound 25. |
| `improper command pipelining` | Harmless — test client sent commands before banner. |
| Mail accepted but Rails doesn't see it | Password mismatch — `.env.ENVNAME` ≠ `credentials.action_mailbox.ingress_password`. |
| Let's Encrypt fails | DNS not resolving yet, or port 80 blocked. |

## File map

| File | Purpose |
|---|---|
| `config/deploy.ENVNAME.yml` | Kamal config — servers, env, accessories |
| `.kamal/secrets.ENVNAME` | Exposes `RAILS_MASTER_KEY` + `RAILS_INBOUND_EMAIL_PASSWORD` to Kamal |
| `.env.ENVNAME` | Gitignored — holds `RAILS_INBOUND_EMAIL_PASSWORD` |
| `config/credentials/ENVNAME.key` | Rails master key (gitignored, back up) |
| `config/credentials/ENVNAME.yml.enc` | Encrypted credentials (in git) |
| `config/environments/ENVNAME.rb` | Rails environment config |
| `config/database.yml` | DB section for ENVNAME |
| `config/recurring.yml` | Background jobs |
| `docker/postfix/Dockerfile` | Postfix image |
| `docker/postfix/entrypoint.sh` | Generates Postfix config at container start |
| `docs/postfix-setup.md` | Reference for legacy host-based Postfix setup |

## Notes

- **SSL** via kamal-proxy / Let's Encrypt. DNS must resolve first.
- **Volumes** created by Docker on first deploy. Renaming orphans old data.
- **Seeds** run via `db:prepare`, idempotent.
- **Multiple apps** can share a server — kamal-proxy routes by hostname.
- **Postfix logs** are ephemeral (Docker stdout), lost on container replacement.

## Internal server (no public internet)

If the server can reach the internet but isn't reachable from outside:

```yaml
proxy:
  ssl: false
  host: INTERNAL_HOSTNAME_OR_IP
```

Override the SSL enforcement from `production.rb`:

```ruby
# config/environments/ENVNAME.rb
require_relative "production"

Rails.application.configure do
  config.force_ssl = false
  config.assume_ssl = false
end
```

App on `http://INTERNAL_HOSTNAME_OR_IP`. No public DNS needed — use the server IP or an internal DNS entry.

If inbound mail isn't needed in this environment, omit the `accessories.postfix` block entirely.


## Running tests

```bash
bin/rails test
```
