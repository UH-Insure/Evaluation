import argparse, json, time, subprocess, os, uuid, random, pathlib
from datetime import datetime
from typing import List, Dict, Any

try:
    import orjson as jsonlib
    def dumps(o): return jsonlib.dumps(o).decode()
except Exception:
    import json as jsonlib
    def dumps(o): return jsonlib.dumps(o)

OUTDIR = "outputs"

def now_tag():
    return datetime.utcnow().strftime("%Y%m%d_%H%M%S")

def load_tasks(path: str) -> List[Dict[str, Any]]:
    tasks = []
    with open(path, "r") as f:
        for line in f:
            line=line.strip()
            if not line: continue
            tasks.append(json.loads(line))
    return tasks

def pick_model(model_id: str):
    return model_id

def dummy_generate(prompt: str, max_new_tokens: int = 256) -> str:
    return f"-- Generated for prompt: {prompt[:40]}...\nparity : [8] -> Bit\nparity xs = foldl (^) False xs"

def try_compile_with_cryptol(code: str) -> bool:
    tmp = pathlib.Path("tmp_cryptol")
    tmp.mkdir(exist_ok=True)
    src = tmp / f"gen_{uuid.uuid4().hex}.cry"
    src.write_text(code, encoding="utf-8")
    cmd = ["bash", "-lc", f"echo ':l {src}' | cryptol"]
    try:
        out = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
        ok = out.returncode == 0 and b"Type checked." in out.stdout
        return ok
    except Exception:
        return False

def run_harness_if_any(harness_path: str) -> bool:
    if not harness_path: return False
    if not os.path.exists(harness_path): return False
    try:
        out = subprocess.run(["bash","-lc", f"saw {harness_path}"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=300)
        return out.returncode == 0
    except Exception:
        return False

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="Model ID or local path")
    ap.add_argument("--tasks", default="eval/prompts/tasks.jsonl")
    ap.add_argument("--k", type=int, default=5)
    args = ap.parse_args()

    model = pick_model(args.model)
    tag = now_tag()
    outdir = os.path.join(OUTDIR, tag)
    os.makedirs(outdir, exist_ok=True)

    gens_path = os.path.join(outdir, "raw_generations.jsonl")
    metrics_path = os.path.join(outdir, "metrics.json")

    total = 0
    compiles = 0
    verified = 0
    passk_compile = 0
    passk_verify = 0

    rng = random.Random(42)
    tasks = load_tasks(args.tasks)

    with open(gens_path, "w") as gf:
        for t in tasks:
            k = int(t.get("k", args.k))
            compiled_any = False
            verified_any = False
            for i in range(k):
                total += 1
                code = dummy_generate(t["prompt"], t.get("max_new_tokens", 256))
                ok_compile = try_compile_with_cryptol(code)
                if ok_compile:
                    compiles += 1
                    compiled_any = True
                ok_verify = False
                if t.get("harness"):
                    ok_verify = run_harness_if_any(t["harness"])
                    if ok_verify:
                        verified += 1
                        verified_any = True

                row = {
                    "task_id": t["task_id"],
                    "attempt": i,
                    "model": model,
                    "prompt": t["prompt"],
                    "code": code,
                    "compiled": ok_compile,
                    "verified": ok_verify,
                }
                gf.write(dumps(row) + "\n")

            if compiled_any:
                passk_compile += 1
            if verified_any:
                passk_verify += 1

    metrics = {
        "total_attempts": total,
        "compile_successes": compiles,
        "verify_successes": verified,
        "compile_rate": compiles / total if total else 0.0,
        "verify_rate": verified / total if total else 0.0,
        "pass@k_compile": passk_compile / len(tasks) if tasks else 0.0,
        "pass@k_verify": passk_verify / len(tasks) if tasks else 0.0,
        "model": model,
        "timestamp": tag,
    }
    with open(metrics_path, "w") as mf:
        mf.write(dumps(metrics))

    print(json.dumps(metrics, indent=2))

if __name__ == "__main__":
    main()