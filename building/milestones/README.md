# Milestone documents

Working documents of the incremental milestones (see jalons-incrementaux
workflow). Committed documents are versioned here; the in-progress audit
is not tracked by git until Paul commits it.

## Index

| File | Milestone | Status (27/11/2026) |
|------|-----------|---------------------|
| `J1b.md` | J1b - CI builds on 3 OS | done, merged (PR #7, merge commit `4a1d8f8`) |
| `J2a-audit.md` | J2a - audit of fork options + build flags | done, merged (PR #8, merge commit `638d587`) |
| `J2b.md` | J2b - guards, presets, dead flags, class C experiment | done on `ci/j2b-presets`, PR pending |

## J2b summary (as of 28/11/2026)

- Branch `ci/j2b-presets`: guards G1/G2/G4/G5/G6, PYMINOR derivation,
  dead flags removed from CI then production scripts, `CMakePresets.json`
  (3 ci-* families + 6 DJ5 placeholders), class C experiment concluded:
  class A pre-allocation removed from the CI scripts (13 linux,
  1 windows), DRACO_* kept as class B on windows/macos (LNK2019 lesson).
  macOS: experiment CANCELLED 28/11 (decision Paul): after the GMPXX
  breaks (dispatches #66/#70) the mpfr break (dispatch #71) confirmed
  that the delocate wheel chain is nondeterministic on basename
  collisions; an identical configure-time resolution does not prove a
  removal safe there. All 22 macos class A pre-allocations restored to
  the reference values (zero class A removals on macos).
- DJ4 resolution proposed in `J2b.md`: scripts do not consume the presets
  in J2b; J2c implements legacy-*/wheel-* FROM the presets and wires
  consumption (incl. scikit-build-core for the Linux wheel family).
- Production-script removals are NOT covered by CI: validation at Paul's
  next production builds (incl. FBX XML2/ZLIB verdict).
- Living checklist + acted decisions: canvas "j2-audit-presets".
- Long-term memory of the project: Vibe Knowledge topic "cloudcompy".
- Do NOT commit `J2a-fork-vs-base.diff` (raw working diff, repo root).
