---
description: Refactor agent instruction files using the agent-md-refactor skill
argument-hint: "[optional scope or preferences]"
---
Use the `agent-md-refactor` skill to refactor the applicable agent instruction file(s) in this repository (such as `AGENTS.md`, `CLAUDE.md`, or `COPILOT.md`) for progressive disclosure.

${@:-Inspect the repository and identify the applicable instruction file(s).}

Follow the skill's phases and verification checklist. First inspect the files and identify contradictions. If any contradiction needs a policy decision, report the exact conflicting instructions and ask me before editing. Otherwise perform the refactor, preserve all actionable guidance unless you explicitly flag it for deletion, and verify links and coverage. Keep changes scoped to agent instructions; do not alter application or configuration behavior.
