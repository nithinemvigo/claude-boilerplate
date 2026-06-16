# /start

Universal entry point for **any change**: new feature, bug fix, hotfix, refactor, chore, docs, security patch. The classifier sizes the task and picks the branch name; the orchestrator routes to the matching pipeline; each stage stops at its gate for your approval.

## Usage

```
/start <task description>
```

### Examples by change type

**Feature**
- `/start add Stripe subscription billing to checkout`
- `/start build an active-users widget for the dashboard`
- `/start support OAuth login with GitHub`

**Bug fix**
- `/start fix the auth token expiry crash on refresh`
- `/start the N+1 query on the orders endpoint slows the list page`
- `/start the upload fails silently when the file exceeds 10MB`

**Hotfix (prod emergency)**
- `/start hotfix the null-pointer crashing checkout in production`
- `/start hotfix the duplicate-charge bug observed in payment-service`

**Refactor / chore**
- `/start refactor the user service into smaller modules`
- `/start update the README installation steps`
- `/start bump Express to v4.21.x and re-run vulnerability audit`

## What happens

### 1. Classifier runs first (~50 tokens)

`.claude/agents/classifier.md` reads the description and emits three tags:

```
<task_size>nano|standard|full</task_size>
<branch>feature/<slug>  |  bugfix/<slug>  |  hotfix/<slug></branch>
<reason>one-sentence justification</reason>
```

Sizing rules (full set in `classifier.md`):

| Size | Criteria | Pipeline cost |
|---|---|---|
| **nano** | 1–2 files, obvious fix, no contract change, no new deps, no schema change | ~400 tokens |
| **standard** | 2–5 files, contained to one layer, may have a few error paths | ~1500 tokens |
| **full** | new service / cross-cutting / >5 files / security-sensitive / unknown scope | ~4000+ tokens |

Branch type is picked by the classifier from the description keywords (`feature/`, `bugfix/`, `hotfix/`).

### 2. Orchestrator activates

`.claude/workflows/orchestrator.md` reads the classifier's tags and loads the matching pipeline:

- **nano** → `.claude/workflows/pipeline-nano.md` — Build lean → Review lean → done
- **standard** → `.claude/workflows/pipeline-standard.md` — CEO lean → Build → Review → Ship lean
- **full** → the 7-agent flow inside `orchestrator.md` — CEO → Eng → [Design] → Build → Testing → Review → Ship

### 3. Pipeline executes, gate by gate

Each stage hands the next agent a structured context, stops at its gate, and waits for your approval before continuing. The commit rule is enforced by the orchestrator: **only the Review-stage agent issues `git commit`**.

## You'll see

```
<task_size>standard</task_size>
<branch>feature/dashboard-active-users</branch>
<reason>Touches 3 files, no contract change, contained to UI layer.</reason>
```

Then the matching pipeline kicks off and the first agent posts its plan.

## Branch naming (handled automatically)

The classifier emits the branch name — you don't choose it manually. Patterns:

| Change type | Branch prefix | Example |
|---|---|---|
| New feature or addition | `feature/` | `feature/stripe-billing` |
| Bug fix | `bugfix/` | `bugfix/auth-token-expiry` |
| Production hotfix | `hotfix/` | `hotfix/payment-null-crash` |

Rules:
- Use the ticket ID if present (`PROJ-123` → `feature/PROJ-123`).
- Otherwise a short lowercase slug (2–4 words, hyphens).
- Never use pipeline tier as prefix (`nano/`, `task/`, `standard/` are wrong).

See `.claude/agents/classifier.md` § "Branch naming" for the full rule set.

## After /start

You'll typically run these as the pipeline progresses:

- `/status` — see where the task is in the pipeline
- `/approve` — pass the current gate
- `/review` — manually trigger code review
- `/ship` — merge and tag (Review approval required first)

## Escalation

If Build discovers mid-task that the scope is bigger than classified, it emits `<escalate>standard|full</escalate>` and the orchestrator re-runs the classifier, reloads the bigger pipeline, and resumes — work on the branch is preserved.

## Arguments

`$ARGUMENTS` — the task description. Passed verbatim to the classifier; the classifier extracts size + change type + branch slug.

## Related files

- `.claude/agents/classifier.md` — sizing + branch naming logic
- `.claude/workflows/orchestrator.md` — stage sequencing + commit-rule enforcement
- `.claude/workflows/pipeline-nano.md` — fast path for tiny changes
- `.claude/workflows/pipeline-standard.md` — medium path with a brief plan
- `.claude/agents/{ceo,eng,design,build,testing,review,ship}.md` — stage agents (loaded as the pipeline progresses)
