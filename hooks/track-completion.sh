#!/bin/bash
# Track Completion Hook (stop)
# Logs task outcome when the agent loop ends, enabling accuracy analysis
# by correlating with the model recommendation from beforeSubmitPrompt.

INPUT=$(cat)

echo "$INPUT" | python3 -c '
import json, sys, os
from datetime import datetime

try:
    data = json.load(sys.stdin)
except:
    sys.exit(0)

status = data.get("status", "unknown")
loop_count = data.get("loop_count", 0)
conversation_id = data.get("conversation_id", "")
generation_id = data.get("generation_id", "")
model = data.get("model", "").lower()

try:
    log_dir = os.path.expanduser("~/.cursor/hooks")
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, "model-matchmaker.ndjson")
    entry = {
        "event": "completion",
        "ts": datetime.now().isoformat(),
        "conversation_id": conversation_id,
        "generation_id": generation_id,
        "model": model,
        "status": status,
        "loop_count": loop_count,
    }
    with open(log_path, "a") as f:
        f.write(json.dumps(entry) + "\n")
except:
    pass
' > /dev/null 2>&1

echo '{}'
exit 0
