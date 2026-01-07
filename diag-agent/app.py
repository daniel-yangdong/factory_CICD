#!/usr/bin/env python3
from flask import Flask, jsonify, request
import subprocess
import os
import uuid
from datetime import datetime

app = Flask(__name__)
LOG_BASE = "/var/log/diag"

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "agent": "diag-agent", "host": os.uname().nodename}) # type: ignore

@app.route('/run', methods=['POST'])
def run_diag():
    # 检查请求是否包含JSON数据
    if not request.is_json:
        return jsonify({"error": "Content-Type must be application/json"}), 400
    
    data = request.json
    if data is None:
        return jsonify({"error": "No JSON data provided"}), 400
    
    sn = data.get("sn", "UNKNOWN")
    test_modules = data.get("modules", ["cpu", "mem", "net", "storage"])
    
    log_dir = os.path.join(LOG_BASE, f"{sn}_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    os.makedirs(log_dir, exist_ok=True)

    results = {}
    exit_code = 0

    # Execute specified modules
    for module in test_modules:
        script = f"/opt/diag-scripts/{module}_test.sh"
        if not os.path.exists(script):
            results[module] = {"status": "ERROR", "message": "Script not found"}
            exit_code = 1
            continue

        cmd = [script, log_dir]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)  # 最长10分钟
            if result.returncode == 0:
                results[module] = {"status": "PASS"}
            else:
                results[module] = {
                    "status": "FAIL",
                    "exit_code": result.returncode,
                    "stderr": result.stderr[-500:]  # 截取最后500字符
                }
                exit_code = result.returncode
        except subprocess.TimeoutExpired:
            results[module] = {"status": "TIMEOUT"}
            exit_code = 255

    return jsonify({
        "sn": sn,
        "timestamp": datetime.utcnow().isoformat(),
        "log_dir": log_dir,
        "results": results,
        "overall": "PASS" if exit_code == 0 else "FAIL"
    }), (200 if exit_code == 0 else 400)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9999, debug=False)