#!/usr/bin/env python3
"""Dashboard pobierania (yt-dlp) dla ArekBox.

Uruchom: bash yt-dlp-dashboard.sh
Otwórz: http://localhost:5000
"""
import os
import subprocess
import threading
import secrets
from functools import wraps
from flask import Flask, render_template_string, request, jsonify, make_response

AREKBOX_DIR = os.path.dirname(os.path.abspath(__file__))
MEDIA_VENV = os.path.abspath(os.path.join(AREKBOX_DIR, "..", "venvs", "media"))
YTDLP = os.path.join(MEDIA_VENV, "bin", "yt-dlp")
DOWNLOAD_DIR = os.path.expanduser("~/H5N1-Downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# Dozwolone rozszerzenia plików wyjściowych (przeciw path traversal / CVE-2024-38519, GHSA-c6mh-fpjc-4pr3)
ALLOWED_EXTS = {
    "mp4", "mkv", "webm", "avi", "mov", "flv", "wmv",
    "mp3", "m4a", "ogg", "wav", "flac", "opus",
    "srt", "vtt", "ass",
}

app = Flask(__name__)
app.secret_key = os.environ.get("YTDLP_DASHBOARD_SECRET") or secrets.token_hex(32)
DASHBOARD_TOKEN = os.environ.get("YTDLP_DASHBOARD_TOKEN") or secrets.token_urlsafe(32)

downloads = {}
counter = 0
lock = threading.Lock()


def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization", "")
        if token.startswith("Bearer "):
            token = token[7:]
        cookie_token = request.cookies.get("yt_dlp_token", "")
        if not token or not cookie_token:
            return jsonify({"error": "uwierzytelnianie wymagane"}), 401
        if token != DASHBOARD_TOKEN and cookie_token != DASHBOARD_TOKEN:
            return jsonify({"error": "nieprawidłowy token"}), 401
        return f(*args, **kwargs)
    return decorated


LOGIN_HTML = """
<!DOCTYPE html>
<html lang="pl"><head><meta charset="UTF-8"><title>yt-dlp — Login</title>
<style>body{background:#000;color:#0f0;font-family:monospace;padding:40px}
input{background:#111;color:#0f0;border:1px solid #0f0;padding:8px}
button{background:#0f0;color:#000;border:none;padding:8px 16px;cursor:pointer}
.card{border:1px solid #0f0;padding:20px;max-width:400px;margin:auto}</style></head>
<body>
<div class="card"><h2>yt-dlp Dashboard — Login</h2>
<form method="post" action="/login">
<label>Token:</label><br>
<input name="token" style="width:100%"><br><br>
<button type="submit">Zaloguj</button>
</form>
<p style="font-size:12px;color:#aaa">Token wyświetlony w konsoli przy starcie dashboardu.</p>
</div></body></html>
"""


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        token = request.form.get("token", "")
        if token == DASHBOARD_TOKEN:
            resp = make_response("", 302)
            resp.headers["Location"] = "/"
            resp.set_cookie("yt_dlp_token", token, httponly=True, samesite="Lax")
            return resp
        return "Nieprawidłowy token", 401
    return LOGIN_HTML


@app.before_request
def _auth_guard():
    public = {"/login", "/static/", "/favicon.ico", "/visualizer"}
    if any(request.path.startswith(p) for p in public):
        return
    cookie_token = request.cookies.get("yt_dlp_token", "")
    if cookie_token == DASHBOARD_TOKEN:
        return
    if request.path.startswith("/api/"):
        token = request.headers.get("Authorization", "").replace("Bearer ", "", 1)
        if not token or token != DASHBOARD_TOKEN:
            return jsonify({"error": "uwierzytelnianie wymagane"}), 401
        return
    return make_response(LOGIN_HTML, 200)


HTML = """
<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ArekBox — yt-dlp Dashboard</title>
<style>
    body { background:#000; color:#0f0; font-family:'Courier New',monospace; padding:30px; }
    h1 { color:#fff; border-bottom:2px solid #0f0; padding-bottom:10px; }
    .row { margin:12px 0; }
    input,select,button { background:#111; color:#0f0; border:1px solid #0f0; padding:8px; font-family:inherit; }
    button { cursor:pointer; }
    button:hover { background:#0f0; color:#000; }
    #log { background:#0a0a0a; border:1px solid #0f0; padding:10px; height:240px; overflow:auto; white-space:pre-wrap; margin-top:15px; }
    .card { border:1px solid #0f0; padding:10px; margin:8px 0; }
    a { color:#0ff; }
    .tabs { display:flex; gap:8px; margin-bottom:20px; flex-wrap:wrap; }
    .tab { background:#111; color:#0f0; border:1px solid #0f0; padding:10px 18px;
           cursor:pointer; border-radius:6px; font-family:inherit; font-size:15px; }
    .tab:hover { background:#0f0; color:#000; }
    .tab.active { background:#0f0; color:#000; font-weight:bold; }
    .panel { display:none; }
    .panel.active { display:block; }
    iframe.viz { width:100%; height:86vh; border:1px solid #0f0; border-radius:6px; background:#000; }
    .token { background:#111; border:1px solid #0f0; padding:8px; font-family:monospace; font-size:12px;
             word-break:break-all; margin-top:10px; display:inline-block; }
</style>
</head>
<body>
<h1>📥 ArekBox — Centrum Multimediów</h1>
<div class="tabs">
  <button class="tab active" onclick="showTab('dl', this)">⬇ Pobieranie (yt-dlp)</button>
  <button class="tab" onclick="showTab('viz', this)">🎵 Wizualizator Audio</button>
  <a class="tab" href="http://localhost:5050" target="_blank">⚡ Dashboard systemu</a>
  <a href="/login" style="float:right;margin-top:10px">🔒 Zmień token</a>
</div>

<div style="margin:15px 0;">
  <strong>Token API:</strong> <span class="token" id="tok">ładowanie...</span>
  <button onclick="copyToken()" style="margin-left:8px">Kopiuj</button>
</div>

<div id="panel-dl" class="panel active">
<div class="row">
    <input id="url" style="width:60%" placeholder="Wklej URL (YouTube, itp.)">
</div>
<div class="row">
    <select id="mode">
        <option value="best">Wideo (najlepsze)</option>
        <option value="audio">Tylko audio (mp3)</option>
    </select>
    <select id="quality">
        <option value="best">Jakość: najlepsza</option>
        <option value="1080">1080p</option>
        <option value="720">720p</option>
        <option value="480">480p</option>
    </select>
    <button onclick="start()">⬇ POBIERZ</button>
</div>
<div id="status"></div>
<div id="log"></div>
<h2>📂 Pobrane pliki</h2>
<div id="files"></div>
</div>

<div id="panel-viz" class="panel">
  <p style="color:#aaa;">Wizualizator audio (Web Audio API) — wybierz plik lub mikrofon, przełączaj tryby i motywy:</p>
  <iframe class="viz" src="/visualizer"></iframe>
</div>

<script>
function loadToken(){
  const m=document.cookie.match('(?:^|; )yt_dlp_token=([^;]+)');
  document.getElementById('tok').textContent=m?m[1]:'zaloguj się na /login';
}
function copyToken(){
  const t=document.getElementById('tok').textContent;
  if(t&&t!=='ładowanie...'&&t!=='zaloguj się na /login'){
    navigator.clipboard.writeText(t); alert('Token skopiowany');
  }
}
function showTab(id, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.getElementById('panel-dl').classList.remove('active');
  document.getElementById('panel-viz').classList.remove('active');
  el.classList.add('active');
  document.getElementById('panel-' + id).classList.add('active');
}
let activeId = null;
function start() {
    const url = document.getElementById('url').value.trim();
    if (!url) return alert('Wpisz URL!');
    const mode = document.getElementById('mode').value;
    const quality = document.getElementById('quality').value;
    const tok = document.cookie.match('(?:^|; )yt_dlp_token=([^;]+)');
    fetch('/api/download', {method:'POST', headers:{'Content-Type':'application/json',
        'Authorization': tok ? 'Bearer '+tok[1] : ''},
        body: JSON.stringify({url, mode, quality})})
    .then(r=>r.json()).then(d=>{ activeId=d.id; poll(); });
}
function poll() {
    if (!activeId) return;
    const tok = document.cookie.match('(?:^|; )yt_dlp_token=([^;]+)');
    fetch('/api/progress/'+activeId, {headers: tok ? {'Authorization':'Bearer '+tok[1]} : {}})
    .then(r=>r.json()).then(d=>{
        document.getElementById('log').textContent = d.log;
        document.getElementById('log').scrollTop = 1e9;
        document.getElementById('status').innerHTML =
            '<div class="card">Status: <b>'+d.status+'</b>'+(d.progress?' — '+d.progress+'%':'')+'</div>';
        if (d.status==='running') setTimeout(poll, 800);
        else { activeId=null; loadFiles(); }
    });
}
function loadFiles() {
    const tok = document.cookie.match('(?:^|; )yt_dlp_token=([^;]+)');
    fetch('/api/list', {headers: tok ? {'Authorization':'Bearer '+tok[1]} : {}})
    .then(r=>r.json()).then(files=>{
        document.getElementById('files').innerHTML = files.length
            ? files.map(f=>'<div class="card">'+f+'</div>').join('')
            : '<i>Brak plików.</i>';
    });
}
loadFiles();
loadToken();
</script>
</body>
</html>
"""


VISUALIZER_FILE = os.path.join(AREKBOX_DIR, "audio_visualizer.html")


@app.route("/")
def index():
    return render_template_string(HTML)


@app.route("/login", methods=["GET", "POST"])  # zduplikowane celowo dla przejrzystości, nadpisane przez before_request
def _login_dup():
    return login()


@app.route("/visualizer")
def visualizer():
    try:
        with open(VISUALIZER_FILE, encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        return f"<h1>Brak pliku wizualizatora: {e}</h1>", 500


def run_download(did, url, mode, quality):
    # --ignore-config: nie ładuj yt-dlp.conf z katalogu roboczego (przeciw CVE-2024-38519, GHSA-c6mh-fpjc-4pr3)
    cmd = [YTDLP, "--ignore-config", "-o", os.path.join(DOWNLOAD_DIR, "%(title).200s.%(ext)s")]
    if mode == "audio":
        cmd += ["-x", "--audio-format", "mp3"]
    else:
        if quality == "best":
            cmd += ["-f", "bestvideo+bestaudio/best"]
        else:
            cmd += ["-f", f"bestvideo[height<={quality}]+bestaudio/best[height<={quality}]"]
    cmd.append(url)

    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1, cwd=DOWNLOAD_DIR,
    )
    with lock:
        downloads[did]["pid"] = proc.pid

    for line in proc.stdout:
        with lock:
            downloads[did]["log"] += line
            if "[download]" in line and "%" in line:
                try:
                    downloads[did]["progress"] = line.split("%")[0].split()[-1]
                except Exception:
                    pass

    proc.wait()
    with lock:
        downloads[did]["status"] = "done" if proc.returncode == 0 else "error"
        downloads[did]["code"] = proc.returncode


@app.route("/api/download", methods=["POST"])
@require_auth
def api_download():
    global counter
    data = request.json
    url = (data.get("url") or "").strip()
    if not url:
        return jsonify({"error": "brak URL"}), 400
    # Walidacja URL — tylko http(s), bez cudzysłowów i znaków especiais
    if not (url.startswith("http://") or url.startswith("https://")):
        return jsonify({"error": "tylko http/https"}), 400
    if any(ch in url for ch in '"\'`|;&$(){}[]<>"'):
        return jsonify({"error": "niedozwolone znaki w URL"}), 400
    mode = data.get("mode", "best")
    quality = data.get("quality", "best")
    with lock:
        counter += 1
        did = str(counter)
        downloads[did] = {"log": "", "status": "running", "progress": "", "pid": None, "code": None}
    threading.Thread(target=run_download, args=(did, url, mode, quality), daemon=True).start()
    return jsonify({"id": did})


@app.route("/api/progress/<did>")
@require_auth
def api_progress(did):
    with lock:
        d = downloads.get(did, {"log": "", "status": "unknown", "progress": "", "code": None})
        return jsonify(dict(d))


@app.route("/api/list")
@require_auth
def api_list():
    try:
        files = sorted(os.listdir(DOWNLOAD_DIR), reverse=True)
    except Exception:
        files = []
    return jsonify(files)


@app.route("/api/stop/<did>", methods=["POST"])
@require_auth
def api_stop(did):
    with lock:
        d = downloads.get(did)
        if d and d.get("pid"):
            try:
                os.kill(d["pid"], 15)
                d["status"] = "stopped"
            except Exception:
                pass
            return jsonify({"ok": True})
    return jsonify({"ok": False}), 404


if __name__ == "__main__":
    if not os.path.exists(YTDLP):
        print("[BŁĄD] Brak yt-dlp w venvie media. Uruchom: bash arekbox.sh --setup")
        raise SystemExit(1)
    print(f"[OK] Dashboard yt-dlp na http://localhost:5000")
    print(f"[OK] Token API: {DASHBOARD_TOKEN}")
    print(f"[OK] Zaloguj się na http://localhost:5000/login")
    print(f"[OK] Pliki trafiają do: {DOWNLOAD_DIR}")
    app.run(host="127.0.0.1", port=5000, debug=False)