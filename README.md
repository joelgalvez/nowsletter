*NOWSLETTER* ([nowsletter.org](https://nowsletter.org)) is a collaborative tool for collecting events from newsletters using local AI and to share the work of doing the corrections.



This project has two parts:

1. *NOWSLETTER* A web server. Can run on a VPS, or similar
2. *RUNMODEL* The LLM client (calls llama-server). Runs on a private network.

The idea is that you got some computer on your own work/home network that does the inference. For security reasons, the web server can't contact the LLM server directly. Instead the LLM client contacts the web server and creates a web socket to wait for jobs.

## How to set this up
- See [`docs/self-hosting.md`](docs/self-hosting.md)
