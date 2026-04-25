#!/bin/bash
set -euo pipefail

: "${MAIL_DOMAIN:?MAIL_DOMAIN is required}"
: "${APP_DOMAIN:?APP_DOMAIN is required}"
: "${RAILS_INBOUND_EMAIL_PASSWORD:?RAILS_INBOUND_EMAIL_PASSWORD is required}"

echo "$MAIL_DOMAIN" > /etc/mailname

# main.cf
cat > /etc/postfix/main.cf <<EOF
myhostname = $(hostname -f)
mydestination = \$myhostname, localhost.localdomain, localhost
myorigin = /etc/mailname
inet_interfaces = all
inet_protocols = all

smtpd_client_connection_rate_limit = 10
smtpd_client_message_rate_limit = 30

smtpd_relay_restrictions = permit_mynetworks reject_unauth_destination

maillog_file = /dev/stdout

virtual_mailbox_domains = $MAIL_DOMAIN
virtual_mailbox_maps = hash:/etc/postfix/virtual_mailbox
virtual_transport = webhook
EOF

# Catchall map
echo "@$MAIL_DOMAIN    ok" > /etc/postfix/virtual_mailbox
postmap /etc/postfix/virtual_mailbox

# Webhook script
AUTH_HEADER=$(echo -n "actionmailbox:$RAILS_INBOUND_EMAIL_PASSWORD" | base64)
cat > /usr/local/bin/postfix-to-rails <<EOF
#!/bin/bash
exec /usr/bin/curl -s -X POST \
  -H "Content-Type: message/rfc822" \
  -H "Authorization: Basic $AUTH_HEADER" \
  --data-binary @- \
  https://$APP_DOMAIN/rails/action_mailbox/relay/inbound_emails
EOF
chown nobody:nogroup /usr/local/bin/postfix-to-rails
chmod 700 /usr/local/bin/postfix-to-rails

# Webhook transport in master.cf
if ! grep -q "^webhook" /etc/postfix/master.cf; then
  cat >> /etc/postfix/master.cf <<'EOF'
webhook unix - n n - - pipe
  flags=DRhu user=nobody argv=/usr/local/bin/postfix-to-rails
EOF
fi

# Validate
postfix check

# Run in foreground
echo "Postfix ready: @$MAIL_DOMAIN -> https://$APP_DOMAIN/rails/action_mailbox/relay/inbound_emails"
exec postfix start-fg
