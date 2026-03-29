#!/usr/bin/env bash
# =============================================================================
# Teacher full validation runner (battle-tested path)
# =============================================================================
# Runs every lab with sudo, captures per-lab logs, and prints a final matrix.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT_DIR}/results/teacher-validation"
LABS=(00 01 02 03 04 05 06 99)

mkdir -p "${OUT_DIR}"

echo "[info] Validating sudo access upfront..."
sudo -v

echo "[info] Running labs: ${LABS[*]}"

declare -A EXIT_CODES
for lab in "${LABS[@]}"; do
  log_file="${OUT_DIR}/lab-${lab}.log"
  echo "[run] Lab ${lab} -> ${log_file}"

  if sudo bash "${ROOT_DIR}/run-labs.sh" --validate --lab "${lab}" >"${log_file}" 2>&1; then
    EXIT_CODES["${lab}"]=0
    echo "[ok]  Lab ${lab}"
  else
    EXIT_CODES["${lab}"]=1
    echo "[fail] Lab ${lab} (see ${log_file})"
  fi
done

echo
echo "========== Teacher Validation Matrix =========="
fail_count=0
for lab in "${LABS[@]}"; do
  code="${EXIT_CODES[${lab}]}"
  echo "Lab ${lab}: EXIT ${code}"
  if [[ "${code}" -ne 0 ]]; then
    fail_count=$((fail_count + 1))
  fi
done

echo "==============================================="
if [[ "${fail_count}" -ne 0 ]]; then
  echo "[result] ${fail_count} lab(s) failed"
  exit 1
fi

echo "[result] All labs passed"
