*NOWSLETTER* ([nowsletter.org](https://nowsletter.org)) is a collaborative tool for collecting events from newsletters using local AI and to share the work of doing the corrections.



This project has two parts:

1. *NOWSLETTER* The (web) server - (this project). Can run on a VPS, or similar
2. *RUNMODEL* The LLM server (actually the client) - ([github.com/joelgalvez/runmodel](https://github.com/joelgalvez/runmodel)). Runs on a private network, that also runs llama-server.

The idea is that you got some computer on your own work/home network that does the inference. For security reasons, the web server can't contact the LLM server directly. Instead the LLM Server contacts the web server and creates a web socket to wait for jobs.

The web server also runs postfix and waits for incoming email. Postfix is only for recieving email, for sending use some other SMTP service. Every place you subscribe to gets their own secret email inbox (secret-xxxxxx@email.com). Any other email is ignored.

---

## How to set this up
- See [`docs/self-hosting.md`](docs/self-hosting.md)
