# Milestone documents

Working documents of the incremental milestones (see jalons-incrementaux
workflow). Committed documents are versioned here; the in-progress audit
is not tracked by git until Paul commits it.

## Index

| File | Milestone | Status (25/11/2026) |
|------|-----------|---------------------|
| `J1b.md` | J1b - CI builds on 3 OS | done, merged (PR #7, merge commit `4a1d8f8`) |
| `J2a-audit.md` | J2a - audit of fork options + build flags | done, VALIDATED by Paul 27/11 (guard plan G1/G2/G4/G5/G6, preset decisions DJ1-DJ5) |

## J2a resume notes (as of 25/11/2026 evening)

- Sections: 0 Paul's working method, 1 fork diff classification (families
  A-F), 2 anomalies (with Paul's decisions), 3 upstream strategy, 4 flag
  x family x value matrix (J2a.1), 5 dead flags on the 3 CI platforms
  (J2a.2), 6 pending (J2a.4 impact audit + guards, J2a.5 joint review).
- Decisions acted: DJ1-DJ3, DJ5 (9 preset families: ci-/legacy-/wheel-
  x linux/windows/macos, only ci-* implemented in J2b). DJ4 open.
- Next steps, in order:
  1. J2a.5 first pass: joint review of the full document;
  2. J2a.4: impact audit + CMake guard proposals (material from section 2);
  3. commit of this file by Paul on branch `ci/j2a-audit`
     (message FR, no accents: "J2a : document d audit du fork CloudCompare").
- Living checklist + acted decisions: canvas "j2-audit-presets".
- Long-term memory of the project: Vibe Knowledge topic "cloudcompy".
- Do NOT commit `J2a-fork-vs-base.diff` (raw working diff, repo root).
