# Nowsletter

This is a collaborative tool for collecting events from newsletters using local AI and to share the work of doing the corrections.

1. **Nowsletter** The (web) server - (this project). Can run on a VPS, or similar
2. **Runmodel** The LLM server - ([github.com/joelgalvez/runmodel](https://github.com/joelgalvez/runmodel)). Runs on a private network, that also runs llama-server

The idea is that you got some computer in the closet that does the inference. This setup would have been a lot simpler if the webserver had direct access to llama-server, but I didn't want to expose my private network, so instead i got this roundabout setup: The LLM server calls the web server and creates a web socket and waits for jobs.

The web server also runs postfix and waits for incoming email. Postfix is only for recieving email, for sending use some other SMTP service. Every place you subscribe to gets their own secret email inbox (secret-xxxxxx@email.com). Any other email is ignored.

**How it works:**

- You create a venue and subscribe using its unique email: "secret-xxxxxx@email.com"
- When a new newsletter arrives, the external LLM server finds the events in it
- You might correct some things, maybe publish
- In the dashboard, you send a prefab email with a login link to the authors of the newsletter
- They see the same dashboard and can also do corrections

---

## Get started

- **Self-hosting (Docker Compose)** — see [`docs/self-hosting.md`](docs/self-hosting.md)
- **Kamal** — see [`docs/deploy-instructions.md`](docs/deploy-instructions.md)

