---
name: optimize-classifier
description: Analyze your Model Matchmaker override patterns and tune the local classifier to match your preferences. Use after collecting 50+ recommendations.
---

# Optimize My Classifier

This skill helps you personalize your Model Matchmaker classifier based on your actual usage patterns. After you've collected 50+ recommendations, this skill analyzes when you disagreed with the advisor and tunes your local classifier to match your preferences.

## What This Skill Does

1. **Reads** your local Model Matchmaker logs (`~/.cursor/hooks/model-matchmaker.ndjson`)
2. **Analyzes** when you overrode the advisor's recommendations
3. **Finds patterns** in the prompts where you disagreed (common words, task types)
4. **Suggests** keyword additions to your `model-advisor.sh` file
5. **Updates** your classifier (with your approval) so future recommendations match your preferences

**Privacy:** Everything happens locally. No data leaves your machine. You review and approve every change.

## Instructions for the AI

You are helping the user optimize their Model Matchmaker classifier based on their personal override patterns. Follow these steps:

### Step 1: Read and Validate Log File

Read the NDJSON log file at `~/.cursor/hooks/model-matchmaker.ndjson`.

Check if there's enough data:
- Need at least 50 `recommendation` events total
- Need at least 5 `OVERRIDE` events to find patterns
- If not enough data, tell the user: "You need more usage data. Come back after 50+ prompts with at least a few overrides."

### Step 2: Analyze Override Patterns

Filter to `action: "OVERRIDE"` events and group by model direction:

**Group A: User preferred Opus over recommended Haiku/Sonnet**
- These are prompts where the classifier said "use a cheaper model" but you said "no, I need Opus"
- Extract common words from `prompt_snippet` fields in this group

**Group B: User preferred Sonnet over recommended Opus**
- These are prompts where the classifier said "use Opus" but you said "no, Sonnet is fine"
- Extract common words from `prompt_snippet` fields in this group

**Group C: User preferred Sonnet over recommended Haiku**
- Extract common words from `prompt_snippet` fields in this group

**Group D: User preferred Haiku over recommended Sonnet/Opus**
- Extract common words from `prompt_snippet` fields in this group

### Step 3: Extract Keyword Candidates

For each group, find words that appear in 3+ override prompts (minimum frequency threshold).

**Exclude common stop words:**
- the, a, an, is, are, was, were, be, been, being, have, has, had, do, does, did
- in, on, at, to, for, of, with, from, by, about, as, into, through, during
- this, that, these, those, I, you, we, they, it, he, she, me, my, your

**Focus on action verbs and technical terms:**
- Examples: debug, investigate, refactor, optimize, analyze, build, create, fix, update, configure

### Step 4: Generate Proposed Changes

For each keyword group, map to the correct section of `model-advisor.sh`:

**For Group A keywords (user prefers Opus):**
→ Add to `opus_keywords` list around line 46

**For Group B/C keywords (user prefers Sonnet):**
→ Add to `sonnet_patterns` list around line 63

**For Group D keywords (user prefers Haiku):**
→ Add to `haiku_patterns` list around line 53

### Step 5: Calculate Impact

For each proposed keyword:
- Count how many past overrides would become correct recommendations if this keyword were added
- Show confidence: "3 overrides → 'debug' should trigger Opus"

### Step 6: Present Recommendations

Output in this format:

```markdown
# Classifier Optimization Report

## Your Usage Summary

- Total recommendations: N
- Overrides: M (X.X%)
- Ready for optimization: [Yes/No - need 5+ overrides]

## Patterns Found

### You prefer Opus for:

**Keyword: "debug"**
- Frequency: 5 overrides
- Current behavior: Recommends Sonnet
- Proposed: Add "debug" to opus_keywords
- Impact: 5 past overrides would become correct recommendations

**Keyword: "investigate"**
- Frequency: 3 overrides
- Current behavior: Recommends Sonnet
- Proposed: Add "investigate" to opus_keywords
- Impact: 3 past overrides would become correct recommendations

[Repeat for other keywords]

### You prefer Sonnet over Opus for:

[Same structure]

### You prefer Haiku for:

[Same structure]

## Proposed Changes to ~/.cursor/hooks/model-advisor.sh

**Add to opus_keywords (line 46):**
```python
opus_keywords = [
    "architect", "architecture", "evaluate", "tradeoff", "trade-off",
    "strategy", "strategic", "compare approaches", "why does", "deep dive",
    "redesign", "across the codebase", "investor", "multi-system",
    "complex refactor", "analyze", "analysis", "plan mode", "rethink",
    "high-stakes", "critical decision",
    # NEW - Added based on your override patterns:
    "debug", "investigate"  # 8 overrides support this
]
```

**Add to sonnet_patterns (line 63):**
[Show specific regex additions if any]

## Next Steps

Would you like me to apply these changes to your classifier?

1. **Yes** - I'll update ~/.cursor/hooks/model-advisor.sh with these keywords
2. **Some of them** - Tell me which keywords to add
3. **No** - Just show me the analysis, don't change anything

If you approve, I'll:
1. Read your current model-advisor.sh
2. Add the new keywords to the appropriate lists
3. Write the updated file back
4. Confirm the changes

You can test immediately by restarting Cursor or starting a new composer session.
```

### Step 7: Apply Changes (If User Approves)

If user says "yes" or approves specific keywords:

1. Read `~/.cursor/hooks/model-advisor.sh`
2. Locate the appropriate keyword list (opus_keywords, sonnet_patterns, or haiku_patterns)
3. Add the new keywords to the list with a comment explaining they were auto-added
4. Write the file back using the StrReplace tool
5. Confirm: "Updated! Your classifier now recommends [model] for prompts containing [keywords]. Changes take effect in your next Cursor session."

### Important Notes

- Only suggest keywords with 3+ override occurrences (confidence threshold)
- Don't add generic words that could cause false positives ("the", "make", "update")
- Show the user exactly what will change before changing it
- If the user's overrides are inconsistent (sometimes want Opus, sometimes want Sonnet for the same keyword), note that and ask for clarification

---

## How to Use This Skill

As a user, invoke this skill by saying something like:

- "Optimize my Model Matchmaker classifier"
- "Tune my classifier based on my overrides"
- "Analyze my Model Matchmaker usage and improve it"
- "Update my classifier to match my preferences"

The AI will analyze your logs, find patterns, and propose keyword additions. You review and approve before any changes are made.

## When to Run This

- After your first 50-100 prompts (to establish baseline patterns)
- Monthly or quarterly as your workflow evolves
- After a major project shift (switching from backend to frontend work, for example)
- Whenever you notice you're overriding the advisor frequently
