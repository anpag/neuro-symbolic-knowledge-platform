#!/usr/bin/env python3
"""
Platform-Wide End-to-End Certification Runner
Executes comprehensive cross-submodule verification across:
- Section 1: Extraction Agents (LangGraph + Multimodal + 10-Field Triple)
- Section 2: Reasoning Engine (Native Rust GEB Engine + FastAPI Async Jobs)
- Section 3: Dataform Pipeline (Relational SHACL + Deduplication + Partitioning)
- Section 4: Infrastructure (Terraform Cloud Run v2 + Dataform IAM + Eventarc)
- Section 5: Ontology UI (Angular 18 Cytoscape + DLQ Inspector + Memory Cleanups)
- Section 6: Monorepo Orchestration & Unified E2E Test Lifecycle
"""

import os
import sys
import subprocess
import time
from typing import Dict, Any, Tuple

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run_step(step_name: str, cmd: str, cwd: str) -> Tuple[bool, str]:
    print(f"\n==================================================")
    print(f"▶ RUNNING: {step_name}")
    print(f"  Command: {cmd}")
    print(f"  Directory: {cwd}")
    print(f"==================================================")
    start_time = time.time()
    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    elapsed = time.time() - start_time
    status = "PASSED" if result.returncode == 0 else "FAILED"
    print(f"[{status}] in {elapsed:.2f}s")
    if result.returncode != 0:
        print(f"--- Output (last 25 lines) ---")
        lines = result.stdout.strip().split("\n")
        print("\n".join(lines[-25:]))
    return result.returncode == 0, result.stdout


def main():
    print("\n🚀 Starting Neuro-Symbolic Knowledge Platform E2E Certification Pipeline...")
    results = {}

    # 1. Rust Engine Tests
    ok, _ = run_step(
        "Section 2: Native Rust Reasoning Engine cargo test",
        "cargo test",
        os.path.join(ROOT_DIR, "reasoning-engine", "rust_engine")
    )
    results["Rust GEB Engine Tests"] = ok

    # 2. Reasoning Engine Python Tests
    ok, _ = run_step(
        "Section 2: Reasoning Engine Python FastAPI pytest",
        ".venv/bin/pytest -v tests/test_reasoner.py tests/test_api.py tests/test_loader.py",
        os.path.join(ROOT_DIR, "reasoning-engine")
    )
    results["Reasoning Engine Python Tests"] = ok

    # 3. Extraction Agents Tests
    ok, _ = run_step(
        "Section 1: Extraction Agents pytest (LangGraph, Multimodal, Schema Slice)",
        ".venv/bin/pytest -v",
        os.path.join(ROOT_DIR, "extraction-agents")
    )
    results["Extraction Agents Tests"] = ok

    # 4. Dataform SHACL Pipeline Compilation
    ok, _ = run_step(
        "Section 3: Dataform SHACL Pipeline Compilation (32 actions)",
        "npx --yes @dataform/cli compile",
        os.path.join(ROOT_DIR, "dataform-pipeline")
    )
    results["Dataform SHACL Pipeline Compilation"] = ok

    # 5. Terraform Infrastructure Validation
    ok, _ = run_step(
        "Section 4: Infrastructure Terraform Validation",
        "PATH=$HOME/.local/bin:$PATH terraform init -backend=false && PATH=$HOME/.local/bin:$PATH terraform validate",
        os.path.join(ROOT_DIR, "infrastructure")
    )
    results["Infrastructure Terraform Validation"] = ok

    # 6. Angular 18 UI Build
    ok, _ = run_step(
        "Section 5: Ontology UI Production Build (Angular 18 + Cytoscape + DLQ)",
        "npm run build",
        os.path.join(ROOT_DIR, "ontology-ui")
    )
    results["Ontology UI Production Build"] = ok

    # 7. Root E2E Lifecycle Suite
    ok, _ = run_step(
        "Section 6: Root Monorepo E2E Lifecycle Suite",
        f"{os.path.join(ROOT_DIR, 'reasoning-engine', '.venv', 'bin', 'pytest')} -v tests/test_e2e_lifecycle.py",
        ROOT_DIR
    )
    results["Monorepo E2E Lifecycle Suite"] = ok

    # Print Summary Table
    print("\n" + "=" * 70)
    print("🏆 FINAL E2E CERTIFICATION SUMMARY REPORT")
    print("=" * 70)
    all_passed = True
    for suite, passed in results.items():
        status_str = "✅ PASS" if passed else "❌ FAIL"
        if not passed:
            all_passed = False
        print(f"  {suite:<50} {status_str}")
    print("=" * 70)

    if all_passed:
        print("\n🎉 ALL 7/7 CROSS-STACK TEST SUITES PASSED UNCONDITIONALLY!")
        sys.exit(0)
    else:
        print("\n❌ SOME TEST SUITES FAILED. PLEASE REVIEW LOGS.")
        sys.exit(1)


if __name__ == "__main__":
    main()
