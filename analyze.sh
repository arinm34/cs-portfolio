#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://git.doit.wisc.edu/cdis/cs/courses/cs544/misc/calculator"
CLONE_DIR="${CLONE_DIR:-calculator-repo}"
LOG_FILE="${LOG_FILE:-/tmp/ollama.log}"      # <— changed default path
MODEL_NAME="${MODEL_NAME:-gemma3:1b}"

command -v ollama >/dev/null 2>&1 || {
  echo "Error: 'ollama' not found in PATH." >&2
  exit 127
}

rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"
cd "$CLONE_DIR"
git fetch origin main fix --prune

echo "Summarize the following code diff:" > prompt.txt
echo >> prompt.txt
git diff origin/main..origin/fix >> prompt.txt

server_ready() { curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; }

STARTED_LOCALLY=0
if ! server_ready; then
  : > "${LOG_FILE}"
  ollama serve &> "${LOG_FILE}" &
  OLLAMA_PID=$!
  STARTED_LOCALLY=1
else
  OLLAMA_PID=""
fi

cleanup() {
  if [[ "${STARTED_LOCALLY}" -eq 1 ]] && [[ -n "${OLLAMA_PID:-}" ]]; then
    if kill -0 "${OLLAMA_PID}" 2>/dev/null; then
      kill "${OLLAMA_PID}" 2>/dev/null || true
      wait "${OLLAMA_PID}" 2>/dev/null || true
    fi
  fi
}
trap cleanup EXIT

for i in $(seq 1 60); do
  if server_ready; then break; fi
  sleep 1
  if [[ "${STARTED_LOCALLY}" -eq 1 ]] && [[ -n "${OLLAMA_PID:-}" ]] && ! kill -0 "${OLLAMA_PID}" 2>/dev/null; then
    echo "Ollama server exited unexpectedly. See ${LOG_FILE}" >&2
    exit 1
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "Timed out waiting for Ollama. See ${LOG_FILE}" >&2
    exit 1
  fi
done

if ! ollama show "$MODEL_NAME" >/dev/null 2>&1; then
  echo "Pulling model: $MODEL_NAME ..."
  ollama pull "$MODEL_NAME"
fi

echo "----- MODEL SUMMARY (${MODEL_NAME}) -----"
cat prompt.txt | ollama run "$MODEL_NAME"
echo "----- END SUMMARY -----"

