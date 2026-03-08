---
name: share-analytics
description: Build a sanitized analytics report from your Model Matchmaker usage for community contribution. Optional; use optimize-classifier for private tuning instead.
---

# Share Model Matchmaker Analytics

**OPTIONAL SKILL** - This is for contributing data back to the community. You don't need this for personal optimization. Use the `optimize-classifier` skill instead for private, local tuning.

This skill helps you contribute sanitized analytics data back to the Model Matchmaker community to improve the classifier, while protecting your privacy. This is completely optional and not required for Model Matchmaker to work or improve based on your usage.

## What This Skill Does

**Note:** You can optimize your classifier privately using the `optimize-classifier` skill. This "share-analytics" skill is only if you want to contribute aggregated data back to help improve Model Matchmaker for everyone.

1. **Reads** your local Model Matchmaker logs (`~/.cursor/hooks/model-matchmaker.ndjson`)
2. **Sanitizes** prompt snippets by removing project names, file paths, and personal details
3. **Categorizes** prompts using a standard 20-category taxonomy
4. **Aggregates** patterns to show where the classifier succeeded or failed
5. **Shows you** the sanitized report for review before you share it

## Instructions for the AI

You are helping the user create a privacy-safe contribution report from their Model Matchmaker usage data. Follow these steps:

### Step 1: Read the Log File

Read the NDJSON log file at `~/.cursor/hooks/model-matchmaker.ndjson`. Each line is a JSON object with this structure:

```json
{
  "event": "recommendation",
  "ts": "2026-03-06T15:44:39.040834",
  "conversation_id": "abc123",
  "generation_id": "gen456",
  "model": "claude-4-opus",
  "recommendation": "sonnet",
  "action": "ALLOW|BLOCK|OVERRIDE",
  "word_count": 25,
  "prompt_snippet": "First 40 chars of prompt"
}
```

or

```json
{
  "event": "completion",
  "ts": "2026-03-06T15:45:12.123456",
  "conversation_id": "abc123",
  "generation_id": "gen456",
  "model": "claude-4-opus",
  "status": "completed|errored|aborted",
  "loop_count": 0
}
```

### Step 2: Categorize Prompts

Classify each `recommendation` event's `prompt_snippet` into one of these 20 categories. **Never output the literal prompt_snippet** — only the category and a generic pattern description.

**High Frequency Categories (prioritize for training):**
1. `ui_ux_bug_fixes` - Layout, responsive design, overlap, positioning, visual glitches
2. `feature_implementation` - New UI elements, components, flows, capabilities
3. `ai_chat_debugging` - AI chat failures, model config, persona behavior issues
4. `data_persistence` - Likes, votes, profile data, Firestore behavior
5. `testing_qa` - Manual testing, browser automation, test flows

**Medium Frequency Categories:**
6. `cross_platform_alignment` - Bringing web and iOS features/design in sync
7. `build_deployment` - Xcode, build errors, deployment, environment setup
8. `product_strategy` - Strategic questions about product, market, differentiation
9. `feature_design_ux` - Designing flows, UX, feature behavior before implementation
10. `marketing_content` - Social posts, launch content, marketing copy
11. `business_planning` - Partnerships, events, proposals, business documents
12. `documentation_process` - Session logs, TODOs, internal docs
13. `api_service_integration` - Third-party APIs, image generation, external services
14. `pricing_monetization` - Plans, paywalls, pricing logic
15. `plan_execution` - Implementing predefined plans with todos

**Low Frequency Categories:**
16. `platform_architecture` - Tech stack, architecture, platform choices
17. `brand_legal` - DBA, trademarks, brand structure
18. `configuration_oauth` - Firebase, OAuth, auth setup
19. `tool_troubleshooting` - Non-code tools and environment issues
20. `rd_competitive_analysis` - Researching competitors, tech options, cost comparisons

If a prompt doesn't fit any category, use `other`.

### Step 3: Sanitize Prompt Snippets

For each prompt snippet, extract the **task type** without revealing specifics:

**Examples of sanitization:**

- `"build the PaymentService checkout flow"` → Category: `feature_implementation`, Pattern: "multi-component feature build"
- `"Fix the profile page overlap issue on mobile"` → Category: `ui_ux_bug_fixes`, Pattern: "mobile responsive layout fix"
- `"Why is Ross not generating images like before?"` → Category: `ai_chat_debugging`, Pattern: "AI persona behavior regression"
- `"git commit all changes"` → Category: `git_operation` (if you add it, or use `other`), Pattern: "git commit"

**Rules for sanitization:**
- Remove all project/product names (PaymentService, Ross, DoMoreWorld, etc.)
- Remove file paths and code references
- Remove user names and email addresses
- Keep the task category and generic action (e.g., "layout fix", "API integration", "refactor")

### Step 4: Correlate Recommendations with Completions

Match `recommendation` events with `completion` events using `conversation_id`. Calculate:
- How many recommendations led to `completed` vs `errored` outcomes
- Override rate per category
- Error rate when user overrode vs. followed the recommendation

### Step 5: Generate Contribution Report

Output a structured report in this format:

```markdown
# Model Matchmaker Analytics Contribution

**Version:** [Model Matchmaker version from repo]
**Period:** [Date range from logs]
**Total Events:** [N recommendations, M completions]

## Summary Statistics

- Total Recommendations: N
- Allow: X (Y%)
- Block: X (Y%)
- Override: X (Y%)

## Override Analysis by Category

### High-Frequency Categories

**Category: ui_ux_bug_fixes**
- Override count: 12
- Model used → Recommended:
  - opus → sonnet: 8 times
  - sonnet → opus: 4 times
- Generic patterns:
  - "Responsive layout fixes classified as sonnet-level"
  - "Visual positioning bugs"
- Completion outcomes:
  - Completed after override: 10
  - Errored after override: 2

[Repeat for each high-frequency category with overrides]

### Medium-Frequency Categories

[Same structure]

### Low-Frequency Categories

[Same structure]

## Suggested Improvements

Based on the override patterns, suggest:
1. Keywords to add to classifier patterns (generic terms only)
2. Categories that need better model routing
3. Prompt characteristics the classifier missed

## What's NOT in this report

- No literal prompt text
- No project/product names
- No conversation IDs or timestamps
- No user identity
- All data has been generalized to task patterns
```

### Step 6: Present for User Review

Show the user the full sanitized report and ask:

> "This is your privacy-safe contribution report. Review it to make sure nothing sensitive is revealed. If it looks good, you can copy and paste this into the Model Matchmaker GitHub Discussions (or share however you like). Would you like me to make any changes?"

---

## How to Use This Skill

As a user, invoke this skill by saying something like:

- "Generate my Model Matchmaker analytics contribution"
- "Create a sanitized report from my Model Matchmaker logs"
- "Prepare my Model Matchmaker data for sharing"

The AI will read your logs, sanitize them, and show you the report for approval before you share it anywhere.
