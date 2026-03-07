#!/bin/bash
# Model Matchmaker Analytics
# Parses NDJSON logs and prints accuracy/usage metrics.
# Usage: ./hooks/analytics.sh [--json] [--days N]

LOG_PATH="${HOME}/.cursor/hooks/model-matchmaker.ndjson"

if [ ! -f "$LOG_PATH" ]; then
    echo "No analytics data found at $LOG_PATH"
    echo "Start using Model Matchmaker and data will be collected automatically."
    exit 0
fi

DAYS="${2:-0}"
JSON_OUT=false
[ "$1" = "--json" ] && JSON_OUT=true && DAYS="${3:-0}"
[ "$1" = "--days" ] && DAYS="$2"

python3 -c "
import json, sys
from datetime import datetime, timedelta
from collections import Counter, defaultdict

log_path = '$LOG_PATH'
days_filter = int('$DAYS')
json_out = $([[ "$JSON_OUT" == "true" ]] && echo "True" || echo "False")

recs = []
completions = []
cutoff = None
if days_filter > 0:
    cutoff = datetime.now() - timedelta(days=days_filter)

with open(log_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except:
            continue
        if cutoff:
            ts = datetime.fromisoformat(entry.get('ts', ''))
            if ts < cutoff:
                continue
        if entry.get('event') == 'recommendation':
            recs.append(entry)
        elif entry.get('event') == 'completion':
            completions.append(entry)

total_recs = len(recs)
if total_recs == 0:
    print('No recommendation data found.' if not json_out else json.dumps({'error': 'no data'}))
    sys.exit(0)

actions = Counter(r['action'] for r in recs)
rec_types = Counter(r['recommendation'] for r in recs)
models_used = Counter(r['model'] for r in recs)

overrides = [r for r in recs if r['action'] == 'OVERRIDE']
blocks = [r for r in recs if r['action'] == 'BLOCK']
allows = [r for r in recs if r['action'] == 'ALLOW']

override_rate = len(overrides) / total_recs * 100 if total_recs else 0
block_rate = len(blocks) / total_recs * 100 if total_recs else 0

# Override analysis: what was recommended vs what model was used
override_details = Counter()
for o in overrides:
    override_details[f'{o[\"model\"]} (rec: {o[\"recommendation\"]})'] += 1

# Block analysis: what model was being used vs recommendation
block_details = Counter()
for b in blocks:
    block_details[f'{b[\"model\"]} -> {b[\"recommendation\"]}'] += 1

# Completion analysis: correlate recommendations with outcomes
completion_by_conv = {}
for c in completions:
    cid = c.get('conversation_id', '')
    if cid:
        completion_by_conv[cid] = c

rec_by_conv = defaultdict(list)
for r in recs:
    cid = r.get('conversation_id', '')
    if cid:
        rec_by_conv[cid].append(r)

completed_convs = 0
errored_convs = 0
aborted_convs = 0
override_completed = 0
override_errored = 0
for cid, comp in completion_by_conv.items():
    status = comp.get('status', '')
    had_override = any(r['action'] == 'OVERRIDE' for r in rec_by_conv.get(cid, []))
    if status == 'completed':
        completed_convs += 1
        if had_override: override_completed += 1
    elif status == 'error':
        errored_convs += 1
        if had_override: override_errored += 1
    elif status == 'aborted':
        aborted_convs += 1

if json_out:
    print(json.dumps({
        'total_recommendations': total_recs,
        'actions': dict(actions),
        'recommendations': dict(rec_types),
        'models_used': dict(models_used),
        'override_rate': round(override_rate, 1),
        'block_rate': round(block_rate, 1),
        'override_details': dict(override_details),
        'block_details': dict(block_details),
        'completions': {
            'completed': completed_convs,
            'errored': errored_convs,
            'aborted': aborted_convs,
        },
        'override_outcomes': {
            'completed': override_completed,
            'errored': override_errored,
        },
    }, indent=2))
else:
    print('=' * 50)
    print('  MODEL MATCHMAKER ANALYTICS')
    period = f' (last {days_filter} days)' if days_filter > 0 else ''
    print(f'  {total_recs} recommendations tracked{period}')
    print('=' * 50)

    print(f'\n  Actions:')
    for action, count in actions.most_common():
        pct = count / total_recs * 100
        print(f'    {action:>10}: {count:>4} ({pct:.1f}%)')

    print(f'\n  Override rate: {override_rate:.1f}%')
    print(f'  Block rate:    {block_rate:.1f}%')

    if override_details:
        print(f'\n  Override breakdown (you disagreed):')
        for detail, count in override_details.most_common():
            print(f'    {detail}: {count}')

    if block_details:
        print(f'\n  Block breakdown (model mismatch):')
        for detail, count in block_details.most_common():
            print(f'    {detail}: {count}')

    print(f'\n  Recommendations:')
    for rec, count in rec_types.most_common():
        pct = count / total_recs * 100
        print(f'    {rec:>10}: {count:>4} ({pct:.1f}%)')

    print(f'\n  Models used:')
    for model, count in models_used.most_common():
        print(f'    {model}: {count}')

    total_completions = completed_convs + errored_convs + aborted_convs
    if total_completions > 0:
        print(f'\n  Task Outcomes ({total_completions} conversations):')
        print(f'    Completed: {completed_convs}')
        print(f'    Errored:   {errored_convs}')
        print(f'    Aborted:   {aborted_convs}')
        if override_completed + override_errored > 0:
            print(f'\n  Override Outcomes:')
            print(f'    Completed after override: {override_completed}')
            print(f'    Errored after override:   {override_errored}')

    print()
    print('=' * 50)
    print(f'  Log file: {log_path}')
    print('=' * 50)
"
