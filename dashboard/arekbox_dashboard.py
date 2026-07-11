#!/usr/bin/env python3
"""ArekBox Dashboard — live monitor + przeglądarka modułów.

Uruchom: bash arekbox-dashboard.sh
Otwórz:  http://localhost:5050
"""
import os
import re
import time
import subprocess
from flask import Flask, render_template_string, request, jsonify

AREKBOX_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODULES_DIR = os.path.join(AREKBOX_DIR, "modules")

MODULE_DESC = {
    "ai_tools.sh": "Narzędzia AI (Ollama, modele, czaty)",
    "backup_tools.sh": "Kopie zapasowe (rsync, archiwizacja)",
    "cleanup_tools.sh": "Czyszczenie systemu (cache, pakiety)",
    "dev_tools.sh": "Narzędzia developerskie (git, kontenery)",
    "fan_thinkpad.sh": "Sterowanie wentylatorem ThinkPada",
    "gaming_tools.sh": "Optymalizacja pod gaming",
    "multimedia_tools.sh": "Multimedia (konwersje, pobieranie)",
    "optimize_tools.sh": "Optymalizacja systemu",
    "pdf_tools.sh": "Operacje na PDF (split, merge)",
    "security_tools.sh": "Bezpieczeństwo (skany, hardening)",
    "system_info.sh": "Informacje o systemie",
    "terminal_tools.sh": "Ulepszenia terminala",
}

# Bezpieczne, read-only akcje (ściśle whitelisted, bez shell=True)
ACTIONS = {
    "free": (["free", "-h"], None),
    "df": (["df", "-h"], None),
    "uptime": (["uptime"], None),
    "uname": (["uname", "-a"], None),
    "ps": (["ps", "aux", "--sort=-%cpu"], "top15"),
}

app = Flask(__name__)

_net_prev = None
_net_prev_t = 0.0


def load_modules():
    modules = []
    if not os.path.isdir(MODULES_DIR):
        return modules
    for fname in sorted(os.listdir(MODULES_DIR)):
        if not fname.endswith(".sh"):
            continue
        path = os.path.join(MODULES_DIR, fname)
        funcs = []
        try:
            with open(path, encoding="utf-8", errors="ignore") as f:
                for line in f:
                    m = re.match(r"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\s*\)\s*\{?", line)
                    if m and m.group(1) not in ("if", "while", "for", "case", "function"):
                        funcs.append(m.group(1))
        except Exception:
            pass
        modules.append({
            "file": fname,
            "desc": MODULE_DESC.get(fname, "Moduł ArekBox"),
            "funcs": funcs,
        })
    return modules


MODULES = load_modules()


def system_stats():
    global _net_prev, _net_prev_t
    import psutil
    cpu = psutil.cpu_percent(interval=0.3)
    cores = psutil.cpu_percent(percpu=True, interval=0.0)
    vm = psutil.virtual_memory()
    sm = psutil.swap_memory()

    disks = []
    for p in psutil.disk_partitions(all=False):
        try:
            du = psutil.disk_usage(p.mountpoint)
            disks.append({
                "mount": p.mountpoint,
                "fstype": p.fstype,
                "percent": du.percent,
                "used_gb": round(du.used / 1e9, 1),
                "total_gb": round(du.total / 1e9, 1),
            })
        except Exception:
            continue

    net = psutil.net_io_counters()
    now = time.time()
    rate = {"sent_kbps": 0.0, "recv_kbps": 0.0}
    if _net_prev is not None and now - _net_prev_t > 0:
        dt = now - _net_prev_t
        rate["sent_kbps"] = round((net.bytes_sent - _net_prev[0]) / 1024 / dt, 1)
        rate["recv_kbps"] = round((net.bytes_recv - _net_prev[1]) / 1024 / dt, 1)
    _net_prev = (net.bytes_sent, net.bytes_recv)
    _net_prev_t = now

    try:
        load = list(os.getloadavg())
    except Exception:
        load = [0, 0, 0]

    return {
        "hostname": os.uname().nodename,
        "cpu": round(cpu, 1),
        "cores": [round(c, 1) for c in cores],
        "mem_percent": vm.percent,
        "mem_used_gb": round(vm.used / 1e9, 1),
        "mem_total_gb": round(vm.total / 1e9, 1),
        "swap_percent": sm.percent,
        "disks": disks,
        "net": rate,
        "uptime_h": round((time.time() - psutil.boot_time()) / 3600, 1),
        "load": load,
        "procs": len(psutil.pids()),
    }


HTML = """
<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ArekBox — Dashboard</title>
<style>
  :root { --neon:#0f0; --cyan:#0ff; --bg:#000; --panel:#0a0a0a; }
  * { box-sizing:border-box; }
  body { background:var(--bg); color:var(--neon); font-family:'Courier New',monospace; margin:0; padding:20px; }
  h1 { color:#fff; border-bottom:2px solid var(--neon); padding-bottom:10px; letter-spacing:2px; }
  h2 { color:var(--cyan); border-left:4px solid var(--cyan); padding-left:10px; margin-top:30px; }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:12px; margin-top:15px; }
  .card { background:var(--panel); border:1px solid var(--neon); border-radius:6px; padding:12px; }
  .card .v { font-size:24px; color:#fff; }
  .card .l { font-size:12px; opacity:.7; }
  .bar { height:8px; background:#111; border-radius:4px; margin-top:8px; overflow:hidden; }
  .bar > i { display:block; height:100%; background:var(--neon); }
  .cores { display:grid; grid-template-columns:repeat(auto-fit,minmax(40px,1fr)); gap:4px; margin-top:8px; }
  .cores > div { font-size:11px; text-align:center; background:#111; padding:4px 2px; border-radius:3px; }
  table { width:100%; border-collapse:collapse; margin-top:10px; font-size:13px; }
  td,th { border-bottom:1px solid #1a1a1a; padding:5px 8px; text-align:left; }
  th { color:var(--cyan); }
  .mod { background:var(--panel); border:1px solid #1a1a1a; border-radius:6px; padding:10px; margin:8px 0; }
  .mod .fn { color:#aaa; font-size:12px; word-break:break-all; }
  button { background:#111; color:var(--neon); border:1px solid var(--neon); padding:6px 10px;
           font-family:inherit; cursor:pointer; border-radius:4px; }
  button:hover { background:var(--neon); color:#000; }
  a { color:var(--cyan); }
  pre { background:#060606; border:1px solid #1a1a1a; padding:10px; max-height:220px; overflow:auto; white-space:pre-wrap; }
  nav a { margin-right:18px; }
</style>
</head>
<body>
<h1>⚡ AREKBOX DASHBOARD</h1>
<nav>
  <a href="/yt-dlp" target="_blank">📥 yt-dlp Dashboard</a>
  <a href="#" onclick="runTerm();return false;">🖥 Otwórz menu ArekBox (terminal)</a>
</nav>

<h2>📊 Monitor systemu</h2>
<div class="grid">
  <div class="card"><div class="l">CPU</div><div class="v" id="cpu">–</div>
    <div class="bar"><i id="cpuBar" style="width:0%"></i></div></div>
  <div class="card"><div class="l">RAM</div><div class="v" id="mem">–</div>
    <div class="bar"><i id="memBar" style="width:0%"></i></div></div>
  <div class="card"><div class="l">SWAP</div><div class="v" id="swap">–</div></div>
  <div class="card"><div class="l">Uptime</div><div class="v" id="up">–</div></div>
  <div class="card"><div class="l">Load avg</div><div class="v" id="load">–</div></div>
  <div class="card"><div class="l">Procesy</div><div class="v" id="procs">–</div></div>
  <div class="card"><div class="l">Net ↓/↑ KB/s</div><div class="v" id="net">–</div></div>
  <div class="card"><div class="l">Host</div><div class="v" id="host" style="font-size:15px;">–</div></div>
</div>
<div class="l" style="margin-top:10px;">Rdzenie:</div>
<div class="cores" id="cores"></div>

<h2>💽 Dyski</h2>
<div id="disks"></div>

<h2>🔥 Top procesy (CPU)</h2>
<table id="proctab"><tr><th>PID</th><th>Name</th><th>CPU%</th><th>MEM%</th><th>User</th></tr></table>

<h2>🧩 Moduły ArekBox</h2>
<div id="mods"></div>

<h2>🛠 Szybkie akcje (read-only)</h2>
<div id="acts">
  <button data-a="free">free -h</button>
  <button data-a="df">df -h</button>
  <button data-a="uptime">uptime</button>
  <button data-a="uname">uname -a</button>
  <button data-a="ps">ps (top)</button>
</div>
<pre id="actout"></pre>

<script>
function poll() {
  fetch('/api/stats').then(r=>r.json()).then(s=>{
    document.getElementById('cpu').textContent = s.cpu + '%';
    document.getElementById('cpuBar').style.width = s.cpu + '%';
    document.getElementById('mem').textContent = s.mem_used_gb + '/' + s.mem_total_gb + 'G';
    document.getElementById('memBar').style.width = s.mem_percent + '%';
    document.getElementById('swap').textContent = s.swap_percent + '%';
    document.getElementById('up').textContent = s.uptime_h + 'h';
    document.getElementById('load').textContent = s.load.join(' / ');
    document.getElementById('procs').textContent = s.procs;
    document.getElementById('net').textContent = s.net.recv_kbps + ' / ' + s.net.sent_kbps;
    document.getElementById('host').textContent = s.hostname;
    document.getElementById('cores').innerHTML = s.cores.map((c,i)=>
      '<div>'+i+'<br>'+c+'%</div>').join('');
    document.getElementById('disks').innerHTML = s.disks.map(d=>
      '<div class="card" style="margin:6px 0"><div class="l">'+d.mount+
      ' ('+d.fstype+')</div><div class="v" style="font-size:16px">'+d.used_gb+'/'+d.total_gb+
      'G</div><div class="bar"><i style="width:'+d.percent+'%"></i></div></div>').join('');
  }).catch(()=>{});
  fetch('/api/processes?limit=12').then(r=>r.json()).then(ps=>{
    document.getElementById('proctab').innerHTML = '<tr><th>PID</th><th>Name</th><th>CPU%</th><th>MEM%</th><th>User</th></tr>'+
      ps.map(p=>'<tr><td>'+p.pid+'</td><td>'+p.name+'</td><td>'+p.cpu+'</td><td>'+p.mem+'</td><td>'+(p.user||'?')+'</td></tr>').join('');
  }).catch(()=>{});
  setTimeout(poll, 2000);
}
function runTerm() {
  fetch('/api/launch', {method:'POST'}).then(r=>r.json()).then(d=>{
    document.getElementById('actout').textContent = d.ok ? 'Uruchomiono menu w nowym terminalu.' : 'Błąd: ' + d.error;
  });
}
document.querySelectorAll('#acts button').forEach(b=>b.onclick=()=>{
  fetch('/api/action', {method:'POST', headers:{'Content-Type':'application/json'},
    body:JSON.stringify({action:b.dataset.a})}).then(r=>r.json()).then(d=>{
      document.getElementById('actout').textContent = d.ok ? d.output : 'Błąd: ' + d.error;
    });
});
fetch('/api/modules').then(r=>r.json()).then(ms=>{
  document.getElementById('mods').innerHTML = ms.map(m=>
    '<div class="mod"><b style="color:#fff">'+m.file+'</b> — '+m.desc+
    '<div class="fn">funkcje: '+(m.funcs.length?m.funcs.join(', '):'(brak)')+'</div></div>').join('');
});
poll();
</script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(HTML)


@app.route("/api/stats")
def api_stats():
    import psutil
    return jsonify(system_stats())


@app.route("/api/processes")
def api_processes():
    import psutil
    limit = min(int(request.args.get("limit", 12)), 50)
    out = []
    try:
        for p in psutil.process_iter(["pid", "name", "username"]):
            try:
                out.append({
                    "pid": p.info["pid"],
                    "name": p.info["name"] or "?",
                    "cpu": round(p.cpu_percent(interval=None), 1),
                    "mem": round((p.memory_percent() or 0), 1),
                    "user": p.info["username"] or "?",
                })
            except Exception:
                continue
        out.sort(key=lambda x: x["cpu"], reverse=True)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    return jsonify(out[:limit])


@app.route("/api/modules")
def api_modules():
    return jsonify(MODULES)


@app.route("/api/action", methods=["POST"])
def api_action():
    data = request.json or {}
    action = data.get("action", "")
    if action not in ACTIONS:
        return jsonify({"ok": False, "error": "nieznana akcja"}), 400
    args, post = ACTIONS[action]
    try:
        res = subprocess.run(args, capture_output=True, text=True, timeout=10, shell=False)
        out = res.stdout or res.stderr
        if post == "top15":
            out = "\n".join(out.splitlines()[:15])
        return jsonify({"ok": True, "output": out[:4000]})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500


@app.route("/api/launch", methods=["POST"])
def api_launch():
    term = os.environ.get("AREKBOX_TERMINAL", "x-terminal-emulator")
    try:
        subprocess.Popen(
            [term, "-e", f"bash {AREKBOX_DIR}/arekbox.sh"],
            start_new_session=True,
        )
        return jsonify({"ok": True})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500


@app.route("/yt-dlp")
def yt_dlp_redirect():
    from flask import redirect
    return redirect("http://localhost:5000")


if __name__ == "__main__":
    try:
        import psutil  # noqa
    except ImportError:
        print("[BŁĄD] Brak psutil. Zainstaluj: pip install psutil")
        raise SystemExit(1)
    print(f"[OK] ArekBox Dashboard na http://localhost:5050")
    app.run(host="127.0.0.1", port=5050, debug=False)
