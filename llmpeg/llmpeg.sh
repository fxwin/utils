#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  llmpeg [--dry-run|-d] [--smart|-s] "instruction" "path/to/video"

Flags:
  -d, --dry-run    Print output filename only; do not execute ffmpeg
  -s, --smart      Use gpt-5-mini instead of gpt-4.1
  -h, --help       Show this help
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing required command: $cmd"
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

dry_run=0
smart=0

positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dry-run|-DryRun)
      dry_run=1
      shift
      ;;
    -s|--smart|-Smart)
      smart=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        positional+=("$1")
        shift
      done
      ;;
    -*)
      fail "Unknown flag: $1"
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

[[ ${#positional[@]} -eq 2 ]] || {
  usage >&2
  fail "Expected exactly 2 arguments: instruction and input path"
}

instruction="$(trim "${positional[0]}")"
input_path="$(trim "${positional[1]}")"

[[ -n "$instruction" ]] || fail "Instruction cannot be empty"
[[ -n "$input_path" ]] || fail "Input path cannot be empty"
[[ -f "$input_path" ]] || fail "Input not found: $input_path"

require_cmd ffmpeg
require_cmd curl
require_cmd jq

[[ -n "${OPENAI_API_KEY:-}" ]] || fail "OPENAI_API_KEY is not set"

model="gpt-4.1"
if [[ "$smart" -eq 1 ]]; then
  model="gpt-5-mini"
fi

api_url="https://api.openai.com/v1/responses"
input_name="$(basename -- "$input_path")"
ext=""
if [[ "$input_name" == *.* && "$input_name" != .* ]]; then
  ext=".${input_name##*.}"
elif [[ "$input_name" == .*.* ]]; then
  ext=".${input_name##*.}"
fi
default_out="llmpeg_out${ext}"

read -r -d '' system_prompt <<'EOF' || true
You write safe, correct ffmpeg commands.

Return ONLY JSON with this schema:
{
  "args": ["ffmpeg", "..."],
  "output": "filename.mp4"
}

Rules:
- Single ffmpeg invocation only.
- Include "-y".
- Do not reduce quality unless explicitly asked.
- Prefer stream copy when possible.
- If re-encoding is required, use H.264 video + AAC audio.
- Use the input path provided verbatim.
- Do not expand to absolute paths.
- Output must be a NEW file.
- Write output in the same directory unless instructed otherwise.
EOF

user_prompt=$(cat <<EOF
Task: $instruction

Input file path: $input_path
Preferred output name: $default_out

Return JSON only.
EOF
)

request_body="$(jq -n \
  --arg model "$model" \
  --arg system "$system_prompt" \
  --arg user "$user_prompt" \
  '{
    model: $model,
    input: [
      { role: "system", content: $system },
      { role: "user", content: $user }
    ],
    text: {
      format: { type: "json_object" }
    }
  }'
)"

if ! response="$(curl -fsS -X POST "$api_url" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$request_body")"; then
  fail "OpenAI request failed"
fi

json_text="$(jq -r '.output_text // empty' <<<"$response")"
if [[ -z "$json_text" ]]; then
  json_text="$(jq -r '[.output[]?.content[]?.text?] | join("")' <<<"$response")"
fi

[[ -n "$json_text" ]] || fail "Model response did not contain output text"

if ! plan="$(jq -c . <<<"$json_text" 2>/dev/null)"; then
  fail "Model did not return valid JSON"
fi

jq -e '.args and (.args | type == "array") and (.args | length >= 2)' <<<"$plan" >/dev/null \
  || fail "Invalid plan: missing or malformed args[]"

argv0="$(jq -r '.args[0]' <<<"$plan")"
if [[ "$(basename -- "$argv0" | tr '[:upper:]' '[:lower:]')" != "ffmpeg" ]]; then
  fail "Refusing to run: argv[0] is not ffmpeg"
fi

input_found="$(jq -r --arg p "$input_path" --arg n "$input_name" \
  '[.args[] | tostring | select(. == $p or . == $n)] | length' <<<"$plan")"
[[ "$input_found" -gt 0 ]] || fail "Refusing to run: input path not present in args"

out_path="$(jq -r '.output // empty' <<<"$plan")"
[[ -n "$out_path" ]] || fail "Invalid plan: missing output"
[[ "$out_path" != "$input_path" ]] || fail "Refusing: output equals input"

mapfile -t ffmpeg_cmd < <(jq -r '.args[] | tostring' <<<"$plan")

pretty_cmd=""
for arg in "${ffmpeg_cmd[@]}"; do
  pretty_cmd+="$(printf '%q ' "$arg")"
done

echo "" >&2
echo "Executing:" >&2
echo "$pretty_cmd" >&2
echo "" >&2

if [[ "$dry_run" -eq 1 ]]; then
  echo "$out_path"
  exit 0
fi

if ! "${ffmpeg_cmd[@]}"; then
  fail "ffmpeg failed"
fi

echo "$out_path"
