#!/usr/bin/env python3
"""Servidor leve de health/info do Hermes Ultimate Environment.

Usa apenas a biblioteca padrão (sem dependências extras). Expõe:
  GET /health, /healthz  -> status ao vivo (JSON)
  GET /release.json      -> inventário de versões/bibliotecas (JSON, snapshot do build)
  GET / , /release       -> página HTML com versões e bibliotecas

Configuração por ambiente:
  HERMES_INFO_BIND  (default 0.0.0.0)
  HERMES_INFO_PORT  (default 8080)
  HERMES_INFO_DATA  (default /opt/hermes/info/versions.json)
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from html import escape
import json
import os
import time

DATA_PATH = os.environ.get("HERMES_INFO_DATA", "/opt/hermes/info/versions.json")
BIND = os.environ.get("HERMES_INFO_BIND", "0.0.0.0")
PORT = int(os.environ.get("HERMES_INFO_PORT", "8080"))
START = time.time()


def load_data():
    try:
        with open(DATA_PATH, encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:  # arquivo ausente/corrompido não derruba o server
        return {"image_version": "unknown", "build_date": "?", "error": str(e)}


DATA = load_data()


def render_html(d):
    def section(title, items):
        rows = "".join(
            f"<tr><td class='k'>{escape(str(k))}</td><td class='v'>{escape(str(val) or '—')}</td></tr>"
            for k, val in items.items()
        )
        return f"<h2>{escape(title)}</h2><table>{rows}</table>"

    def pre(title, text):
        return f"<h2>{escape(title)}</h2><pre>{escape(text or '—')}</pre>"

    libs = d.get("libraries", {})
    return f"""<!doctype html>
<html lang="pt-br"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hermes Ultimate Environment — {escape(str(d.get('image_version')))}</title>
<style>
  body{{font-family:system-ui,Segoe UI,Roboto,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem;color:#1b1f24;line-height:1.5}}
  header{{border-bottom:2px solid #eaecef;padding-bottom:.6rem;margin-bottom:1rem}}
  h1{{font-size:1.5rem;margin:0}} .sub{{color:#586069;font-size:.9rem}}
  h2{{font-size:1.05rem;margin:1.4rem 0 .4rem;color:#0b3d91}}
  table{{border-collapse:collapse;width:100%}}
  td{{border-bottom:1px solid #eef0f2;padding:.3rem .5rem;vertical-align:top;font-size:.92rem}}
  td.k{{color:#586069;width:32%;white-space:nowrap}} td.v{{font-family:ui-monospace,Menlo,monospace}}
  pre{{background:#f6f8fa;border:1px solid #eaecef;border-radius:6px;padding:.7rem;overflow:auto;font-size:.82rem}}
  .badge{{display:inline-block;background:#0b3d91;color:#fff;border-radius:999px;padding:.1rem .6rem;font-size:.8rem}}
  footer{{margin-top:2rem;color:#9aa0a6;font-size:.8rem}}
</style></head><body>
<header>
  <h1>🛰️ Hermes Ultimate Environment</h1>
  <div class="sub">Release <span class="badge">{escape(str(d.get('image_version')))}</span>
  &middot; build {escape(str(d.get('build_date')))}</div>
</header>
{section("Runtimes", d.get("runtimes", {}))}
{section("CLIs de IA", d.get("ai_clis", {}))}
{section("CLIs de Cloud / DevOps", d.get("cloud_clis", {}))}
{pre("Bibliotecas Python (venv hermes-agent)", libs.get("pip_hermes"))}
{pre("Pacotes npm globais", libs.get("npm_global"))}
<footer>/health · /release.json &middot; Hermes Ultimate Environment</footer>
</body></html>"""


class Handler(BaseHTTPRequestHandler):
    server_version = "HermesInfo/1.0"

    def _send(self, code, body, ctype):
        payload = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype + "; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(payload)

    def do_GET(self):
        path = self.path.split("?", 1)[0].rstrip("/") or "/"
        if path in ("/health", "/healthz"):
            self._send(200, json.dumps({
                "status": "ok",
                "version": DATA.get("image_version"),
                "uptime_s": round(time.time() - START, 1),
            }), "application/json")
        elif path == "/release.json":
            self._send(200, json.dumps(DATA, ensure_ascii=False, indent=2), "application/json")
        elif path in ("/", "/release"):
            self._send(200, render_html(DATA), "text/html")
        else:
            self._send(404, json.dumps({"error": "not found", "path": path}), "application/json")

    do_HEAD = do_GET

    def log_message(self, *args):  # silencia o log padrão (vai para o stderr do container)
        pass


if __name__ == "__main__":
    httpd = ThreadingHTTPServer((BIND, PORT), Handler)
    print(f"Hermes info server em http://{BIND}:{PORT}  (dados: {DATA_PATH})", flush=True)
    httpd.serve_forever()
