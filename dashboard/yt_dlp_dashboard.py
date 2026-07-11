#!/usr/bin/env python3
"""Dashboard pobierania (yt-dlp) dla ArekBox.

Uruchom: bash yt-dlp-dashboard.sh
Otwórz: http://localhost:5000
"""
import os
import subprocess
import threading
from flask import Flask, render_template_string, request, jsonify

AREKBOX_DIR = os.path.dirname(os.path.abspath(__file__))
MEDIA_VENV = os.path.abspath(os.path.join(AREKBOX_DIR, "..", "venvs", "media"))
YTDLP = os.path.join(MEDIA_VENV, "bin", "yt-dlp")
DOWNLOAD_DIR = os.path.expanduser("~/H5N1-Downloads")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

app = Flask(__name__)

downloads = {}
counter = 0
lock = threading.Lock()


def run_download(did, url, mode, quality):
    cmd = [YTDLP, "-o", os.path.join(DOWNLOAD_DIR, "%(title).200s.%(ext)s")]
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
</style>
</head>
<body>
<h1>📥 ArekBox — Centrum Multimediów</h1>
<div class="tabs">
  <button class="tab active" onclick="showTab('dl', this)">⬇ Pobieranie (yt-dlp)</button>
  <button class="tab" onclick="showTab('viz', this)">🎵 Wizualizator Audio</button>
  <a class="tab" href="http://localhost:5050" target="_blank">⚡ Dashboard systemu</a>
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
    fetch('/api/download', {method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify({url, mode, quality})})
    .then(r=>r.json()).then(d=>{ activeId=d.id; poll(); });
}
function poll() {
    if (!activeId) return;
    fetch('/api/progress/'+activeId).then(r=>r.json()).then(d=>{
        document.getElementById('log').textContent = d.log;
        document.getElementById('log').scrollTop = 1e9;
        document.getElementById('status').innerHTML =
            '<div class="card">Status: <b>'+d.status+'</b>'+(d.progress?' — '+d.progress+'%':'')+'</div>';
        if (d.status==='running') setTimeout(poll, 800);
        else { activeId=null; loadFiles(); }
    });
}
function loadFiles() {
    fetch('/api/list').then(r=>r.json()).then(files=>{
        document.getElementById('files').innerHTML = files.length
            ? files.map(f=>'<div class="card">'+f+'</div>').join('')
            : '<i>Brak plików.</i>';
    });
}
loadFiles();
</script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(HTML)


VISUALIZER_FILE = os.path.join(AREKBOX_DIR, "audio_visualizer.html")


@app.route("/visualizer")
def visualizer():
    try:
        with open(VISUALIZER_FILE, encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        return f"<h1>Brak pliku wizualizatora: {e}</h1>", 500


@app.route("/api/download", methods=["POST"])
def api_download():
    global counter
    data = request.json
    url = (data.get("url") or "").strip()
    if not url:
        return jsonify({"error": "brak URL"}), 400
    mode = data.get("mode", "best")
    quality = data.get("quality", "best")
    with lock:
        counter += 1
        did = str(counter)
        downloads[did] = {"log": "", "status": "running", "progress": "", "pid": None, "code": None}
    threading.Thread(target=run_download, args=(did, url, mode, quality), daemon=True).start()
    return jsonify({"id": did})


@app.route("/api/progress/<did>")
def api_progress(did):
    with lock:
        d = downloads.get(did, {"log": "", "status": "unknown", "progress": "", "code": None})
        return jsonify(dict(d))


@app.route("/api/list")
def api_list():
    try:
        files = sorted(os.listdir(DOWNLOAD_DIR), reverse=True)
    except Exception:
        files = []
    return jsonify(files)


@app.route("/api/stop/<did>", methods=["POST"])
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
    print(f"[OK] Pliki trafiają do: {DOWNLOAD_DIR}")
    app.run(host="127.0.0.1", port=5000, debug=False)
