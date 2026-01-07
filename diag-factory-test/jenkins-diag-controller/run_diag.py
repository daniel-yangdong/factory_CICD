#!/usr/bin/env python3

import requests
import sys
import json
import argparse
import time

def run_diag(target_ip, sn, modules, timeout=600):
    url = f"http://{target_ip}:9999/run"
    payload = {
        "sn": sn,
        "modules": modules
    }

    try:
        print(f"[INFO] Starting Diag on {target_ip} for SN={sn}")
        resp = requests.post(url, json=payload, timeout=10)
        
        if resp.status_code == 200:
            result = resp.json()
            print(json.dumps(result, indent=2))
            
            # Save result locally (for Jenkins archiving)
            with open(f"diag_result_{sn}.json", "w") as f:
                json.dump(result, f, indent=2)
            
            if result["overall"] == "PASS":
                print(f"[SUCCESS] Diag PASSED for {sn}")
                return 0
            else:
                print(f"[ERROR] Diag FAILED for {sn}")
                return 1
        else:
            print(f"[ERROR] API returned {resp.status_code}: {resp.text}")
            return 2

    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Failed to connect to {target_ip}: {e}")
        return 3

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", required=True, help="Target server IP")
    parser.add_argument("--sn", required=True, help="Serial Number")
    parser.add_argument("--modules", nargs="+", default=["cpu","mem","net","storage"])
    args = parser.parse_args()

    sys.exit(run_diag(args.ip, args.sn, args.modules))