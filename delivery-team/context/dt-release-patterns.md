# Release Management Patterns — delivery-team

Reference file for all release management skills. Defines progressive delivery patterns, rollback strategies, stakeholder tiers, monitoring frameworks, feature flag lifecycle, and risk scoring dimensions.

---

## Progressive Delivery Patterns

Six patterns for controlling feature exposure. Selection depends on traffic volume, user type, and risk.

| Pattern | Description | Traffic Requirement | Best For |
|---------|-------------|-------------------|----------|
| **Dark launch** | Code deployed, no user sees it. Feature exists as latent code. | None | Validating infrastructure before any exposure |
| **Ring deployment** | Expanding circles: Internal → Beta → Early Adopters → GA | Named users | **Startup default** — qualitative signal over statistical |
| **Canary release** | Small random sample tests before full rollout | Thousands of users | Statistical validation at scale |
| **Percentage rollout** | Incremental: 1% → 5% → 10% → 25% → 50% → 100% | Thousands of users | Gradual exposure with automated analysis |
| **Cohort/targeted** | Gates based on segment, org, region, plan level | Named segments | B2B tenant-level releases, geographic rollouts |
| **Entitlement** | Permanent flags controlling access by tier/permission | Any | Premium features, plan-gated functionality |

### Ring Model (Default for Startups)

```
Ring 0: Internal / dogfood (employees, @company.com)
Ring 1: Beta / sponsor customers (named orgs, opt-in beta cohort) — UAT phase
Ring 2: Early adopters (wider cohort, power users)
Ring 3: General availability — SIT/GA phase (all users)
```

Not all releases need 4 rings. Tier 3 (incremental) releases may skip directly to Ring 3.

### Ring-to-Tier Communication Mapping

Which stakeholder tiers receive communications at each ring stage:

| Ring | Engineering | CS/Support | Sales | Executives | End Users/Sponsors |
|------|:-----------:|:----------:|:-----:|:----------:|:------------------:|
| Ring 0 (Internal) | Yes | — | — | — | — |
| Ring 1 (Sponsors/UAT) | Yes | Yes | — | — | Sponsors only |
| Ring 2 (Early Adopters) | Yes | Yes | Yes | Yes | — |
| Ring 3 (GA) | Yes | Yes | Yes | Yes | All users |

The communicator agent must respect this mapping — do not send end-user communications before Ring 3 or sales notifications before Ring 2.

### Low-Traffic Alternatives to Percentage Canary

At low volume, statistical significance is unachievable. Use these instead:

- **Named user targeting**: Target specific user IDs or email patterns for dogfooding
- **Opt-in beta cohort**: Segment-based targeting (email list, attribute flag)
- **Tenant/org targeting**: For B2B — release to entire orgs, not individual users
- **Absolute number canary**: Release to "first N users" not "N% of users"

**Principle**: Shift from quantity of signal to quality of signal.

---

## Rollback Strategies

### Rollback Mechanism Types

| Mechanism | Speed | Risk | Use When |
|-----------|-------|------|----------|
| **Feature flag toggle** | Seconds | Lowest | Default — disable flag, feature disappears |
| **Blue-green switch** | Seconds | Low | Infrastructure supports parallel environments |
| **Rolling rollback** | Minutes | Medium | Container orchestration (K8s) reverting pods |
| **Database-aware rollback** | Hours | Highest | Schema migrations involved — see below |

### The V1 Threshold (Pre-Committed Rollback Point)

Borrowed from aviation: V1 is the pre-calculated speed beyond which aborting a takeoff is more dangerous than continuing. In release management:

**V1 = the deployment depth beyond which rollback causes more disruption than a forward hotfix.**

Before every release, define V1 explicitly:
- **Below V1**: Rollback freely at any sign of trouble
- **Above V1**: Forward-fix only — rollback is more dangerous than proceeding

V1 examples:
- "After 30 minutes at Ring 3 with no anomalies" (time-based)
- "After tenant migration Phase 5 completes" (operation-based)
- "After 50% of traffic has been served by new version for 1 hour" (exposure-based)

**V1 is a pre-deployment commitment, not a runtime judgment.** Write it in the release plan. Do not improvise under pressure.

### Forward-Fix vs Rollback Heuristic

- **Additive changes** (new endpoints, new UI, new flags) → fix forward
- **Destructive changes** (schema drops, data migrations, API removals) → pre-defined rollback plan required

### Database Migration Rollback

Database migrations are feature-flag-blind. The expand-contract pattern has a specific point of no return:

```
Phase 1: Add new column (additive — safe)
Phase 2: Dual-write old + new (safe)
Phase 3: Backfill (safe)
Phase 4: Switch reads to new (APPROACHING V1)
Phase 5: Cut reads from old (V1 — POINT OF NO RETURN)
Phase 6: Stop dual-writes (PAST V1 — rollback destroys new-format data)
Phase 7: Drop old column (irreversible)
```

Any release with DDL gets an automatic risk floor of MEDIUM. Destructive DDL = HIGH.

---

## Stakeholder Communication Tiers

Five tiers, each with distinct content focus, channel, and timing.

| Tier | Who | Content Focus | Channel | Timing |
|------|-----|---------------|---------|--------|
| **Engineering** | Developers, SREs, on-call | Commit-level changes, breaking changes, rollback procedures | Slack #alerts, OpsGenie | First |
| **CS/Support** | CSMs, support engineers, SEs | Impact scope, workarounds, customer talking points | Internal status page, Slack, briefing docs | Before external |
| **Sales** | AEs, SAs | Feature descriptions, pricing implications, demo readiness | Email, internal launch brief | Before external |
| **Executives** | VP+, C-suite | Business impact summary, risk, decisions needed | Human-written email (never automated) | Before external |
| **End Users** | Paying users, enterprise sponsors | Business impact, workarounds, changelog | External status page, in-app, email | Last |

### Customer Sponsors vs GA Communication

These are **distinct events**, not timing variants of the same message:

| Dimension | Customer Sponsors | GA (World) |
|-----------|------------------|------------|
| **Framing** | "You are collaborators — your feedback shaped X" | "This is now available — here's why you need it" |
| **Content depth** | Roadmap visibility, feedback channels, named contact | Marketing-polished feature overview, benefit positioning |
| **Commitment** | Expect influence acknowledgment, head start on adoption | Expect it works as described, support available |

### Internal-First Sequencing

Non-negotiable: internal teams are briefed before any external communication. Sales and Support must be prepared before customers receive anything.

---

## Rollback Communication — Pharma 3-Phase Model

Adapted from pharmaceutical clinical trial suspension protocols. The key insight: **ambiguity about rollback scope causes more chaos than the rollback itself.**

### Phase 1: DECISION (Engineering only)

- **Trigger**: Severity assessment (critical = 15-min response SLA)
- **Audience**: Engineering/Ops only
- **Content**: "Initiating rollback to version X. Reason: [hypothesis]. ETA: [X min]. IC: [name]."
- **Channel**: Slack #incidents, OpsGenie

### Phase 2: SCOPE PER STAKEHOLDER TIER (Mandatory — do not skip)

Each tier needs to know what the rollback means **specifically for them**:

| Tier | Scope Statement |
|------|----------------|
| **Engineering** | "Commits X-Y reverted. Schema rollback [included/not]. Flags [list] disabled." |
| **CS/Support** | "Feature [X] unavailable for [duration]. Affected: [segment]. Workaround: [Y]. Do not promise fix time." |
| **Sales** | "Demo env [affected/unaffected]. Pipeline deals touching [feature] — flag to CSM. Do not reference externally." |
| **Executives** | "Service degradation affecting [N%] of [segment] since [time]. Rollback in progress. No data loss. CSMs notified." |
| **Enterprise Sponsors** | "Issue identified with [feature]. Reverting to stable version. Data intact. Will notify when restored." |
| **End Users** | Status page: "Experiencing issues with [feature]. Team working on fix. Next update in 30 minutes." |

### Phase 3: RESTART AUTHORIZATION (Tiered all-clear)

Tier the all-clear the same way as the rollback:
- Engineering: "Service restored. Monitoring 30 min. RCA due in 48 hours."
- CS/Support: "Fully restored at [time]. No customer action needed. Post-incident report within 5 business days."
- Executives: "Resolved. Impact duration: [X min]. RCA scheduled [date]."
- Enterprise Sponsors: "Fully restored as of [time]. Post-incident report within 5 business days."
- End Users: Status page resolved + subscription email.

---

## Post-Deploy Monitoring Tiers

Three canonical tiers with distinct metrics, thresholds, and actions.

| Tier | Window | Focus | Key Metrics | Action on Anomaly |
|------|--------|-------|-------------|-------------------|
| **Tier 1** | 0-15 min | Automated alerts | Error rate (>1-2% over 2 min), latency, health checks | If below V1: ROLLBACK. If above V1: INVESTIGATE. |
| **Tier 2** | 30-60 min | Canary bake | Population-segmented metrics (canary vs control), SLO burn rate | INVESTIGATE if burn rate >2× normal for 1 hr |
| **Tier 3** | 24-72 hr | Business metrics | Conversions, engagement, support ticket trends | REVIEW — lagging indicators, human judgment |

### Critical Technique: Population Segmentation

Never watch aggregate error rates. Always compare canary vs. control populations separately. At 5% canary traffic, aggregate metrics are invisible to the anomaly.

### Error Differentials Over Absolute Thresholds

Compare new version metrics against stable version baseline — not against static thresholds. Reduces false positives significantly.

### Pre-Release SLI Selection

Before every release, define 5 SLIs to monitor. Not exhaustive — focused:
- Prefer HTTP error rates and latency over CPU/memory
- Prioritize user-facing over infrastructure metrics
- Define what "baseline" means for each SLI

---

## Feature Flag Lifecycle

### Six States

```
Live → Ready for code removal → Ready to archive → Archived → Deprecated → Deleted
```

### Four Flag Types (Martin Fowler Taxonomy)

| Type | Lifespan | Dynamism | Purpose |
|------|----------|----------|---------|
| **Release toggle** | 1-2 weeks | Static | Ship incomplete code safely; trunk-based development |
| **Experiment toggle** | Hours to weeks | Highly dynamic | A/B testing; consistent cohort assignment |
| **Ops toggle** | Short (may persist) | Fast reconfig | Kill switches, load shedding |
| **Permissioning toggle** | Years | Per-request | Premium features, beta access, internal dogfood |

### Cleanup Best Practices

- **Dual-PR pattern**: When creating a flag, simultaneously write the removal PR. Minimizes future merge conflicts.
- **Expiration dates**: Set a specific calendar date at creation, not "someday."
- **Definition of done**: Feature is complete when its flag is archived, not when code deploys.
- **Cleanup in DoD**: Flag removal belongs in sprint close, not as separate tech debt.
- **Quarterly audit**: Any flag at 100% for >30 days should be removed.

### Flag Debt Categories

- **Stale**: Rollout complete but code remains
- **Orphaned**: No clear owner after team changes
- **Nested**: Flags within flags (exponential test paths)
- **Unnamed**: Inconsistent naming, no descriptions

---

## Release Risk Scoring

### Five Dimensions

| Dimension | Weight | LOW | MEDIUM | HIGH |
|-----------|--------|-----|--------|------|
| **Schema migrations** | High | No DDL | Additive DDL (new columns, tables) | Destructive DDL (drops, renames, type changes) |
| **New external integrations** | Medium | None | New API dependency, webhook | New OAuth flow, payment provider, auth change |
| **Codebase change scope** | Medium | <5% of codebase, >80% test coverage | 5-15% of codebase or coverage <80% | >15% of codebase or coverage <70% |
| **Rollback complexity** | Medium | Flag-based (seconds) | Blue-green or rolling (minutes) | Manual or DB-aware (hours) |
| **Stakeholder dependencies** | Variable | No commitments | Internal commitments | Enterprise customer SLAs, contractual deadlines |

### Scoring Rules

- Any destructive DDL = automatic HIGH floor
- Any additive DDL = automatic MEDIUM floor
- Final score = highest individual dimension score (not averaged)
- Risk score drives rollout pattern recommendation:
  - LOW → Ring 0 + Ring 3 (skip intermediate rings)
  - MEDIUM → Full 4-ring progression
  - HIGH → Full 4-ring + extended bake times + mandatory rollback rehearsal

---

## Automated vs Human Gates

### Fully Automatable (Gates 1-9)

Static analysis, unit/integration tests, vulnerability scans, artifact integrity, IaC validation, E2E tests, performance tests, observability readiness, rollback health check.

### Human Judgment Required (Gate 10)

Release authorization: DORA metrics context, business timing, compliance, customer commitments. Technical gates must all pass before the human gate is offered.

### Emerging Pattern: SLO/Error-Budget Gating

When error budget is exhausted, releases auto-block without human review. Operationalizes the relationship between deployment risk and user experience commitments.
