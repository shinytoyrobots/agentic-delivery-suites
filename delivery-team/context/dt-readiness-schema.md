# Cross-Functional Readiness Schema

All readiness artifacts (`marketing-readiness.md`, `support-readiness.md`, `gtm-readiness.md`) follow this common structure:

```
# [Domain] Readiness: [Feature Name]
## Launch Tier: [1/2/3]
## Status: [READY / CONDITIONAL / BLOCKED]
## Blocker (if not READY): [Description]

### [Domain-specific checklist]
[See agent methodology for domain-specific items]

### Open items before release
- [ ] [Item] — Owner: [Name] — Due: [Date]
```

## Status definitions

- **READY** — All checklist items complete, no blockers
- **CONDITIONAL** — Ship-ready with named conditions that must resolve by release date
- **BLOCKED** — Cannot ship until blocker is resolved; name the blocker and owner

## Aggregation

The Scrum Master aggregates all readiness artifacts into `cross-functional-readiness.md` at Stage 5. Overall status = the worst individual status (any BLOCKED = overall BLOCKED).
