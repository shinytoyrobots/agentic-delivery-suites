# flow — partial archive

**This is NOT the whole flow suite.** The live suite remains at `flow/`. These three
files were retired on 2026-08-09 by the field-evidence operating-doctrine redesign,
after the 2026-07-28 → 2026-08-10 field trial (7 efforts, ~37 generations, ~144
variants, 16 ships).

| File | Grounds for retirement |
|------|------------------------|
| `commands/flow-anneal.md` | Temperature sat at floor nearly everywhere; reheat triggers effectively never fired; no annealing schedule exists under demand-driven redispatch. |
| `commands/flow-converge.md` | Convergence metric was the most-misread instrument in the suite; criterion-2 ("front stable ≥2 generations") was a dead letter — waived or lineage-read in most real ships. Ship criteria folded into `flow-ship`'s gate; the chavruta trigger moved onto `flow-cull`'s close. |
| `agents/flow-temperature-controller.md` | Retired with the temperature parameter itself. |

Evidence base: a cross-repo value assessment and a two-week retrospective of the field
trial (private working notes). The short version: multi-generation refinement paid for
itself only in the gen-1 wide probe, disagreement-as-defect-detection, and the dissent
layer — not in scheduled wide refinement generations — and the three instruments above
never earned their keep in live use. The operating doctrine that replaced them is
`flow/context/flow-operating-doctrine.md`.
