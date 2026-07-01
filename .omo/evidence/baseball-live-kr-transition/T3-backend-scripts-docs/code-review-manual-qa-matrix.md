# T3 Code Review And Manual QA Matrix

Scope: T3 backend-scripts-docs follow-up evidence for commit `61e6d5d build(release): rename backend and packaging artifacts`.

Decision: PASS for evidence coverage. This file is a review artifact only; no product behavior changes are introduced by this follow-up.

## Inputs Reviewed

- Plan: `/Users/suhohan/Projects/kbo-live/.omo/plans/baseball-live-kr-transition.md`, T3 section.
- Gate rejection: `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs-gate-review.md`.
- T3 implementation commit: `61e6d5d`.
- T3 evidence directory: `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/`.

## Code Review Matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Scope isolation | PASS | `git show --name-only 61e6d5d` shows backend, scripts, docs, tests, and T3 evidence only. No `.gjc` or unrelated `PROJECT_CONTEXT` deletion is committed. |
| No product behavior in this remediation | PASS | This follow-up adds only evidence files under `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/`. |
| Backend env rename behavior | PASS | `backend-spike/src/db/database.ts` uses `BASEBALL_LIVE_KR_DB_PATH`, `BASEBALL_LIVE_KR_DB_ENABLED`, and `BASEBALL_LIVE_KR_DB_DISABLED`; `npm-test.txt` records 91 passing tests. |
| Packaging output names | PASS | `package-backend-macos-rerun.txt`, `package-file-list-rerun.txt`, and `package-key-files-rerun.txt` show `.build/baseball-live-kr-backend-macos`, `run-backend.command`, README, and `.data/baseball-live-kr.sqlite`. |
| Generated run script and README names | PASS | `package-generated-inspection-rerun.txt` shows `BASEBALL_LIVE_KR_DB_ENABLED`, `BASEBALL_LIVE_KR_DB_PATH`, and `.data/baseball-live-kr.sqlite` in generated files. |
| Runtime surface | PASS | `packaged-backend-health.txt` records the packaged backend returning `/health` OK on port 17379. |
| Residual old T3 names | PASS with scoped exception | `residual-old-t3-names.txt` shows no T3-owned legacy backend/package/env hits; the remaining `scripts/fetch-team-brand-assets.sh` hit is D-owned rights/asset scope and was intentionally left untouched. |
| Mac mini package names | PASS for T3 naming; full package N/A | `package-macmini-runtime-name-probe.txt` shows `BaseballLiveKR.app`, `baseball-live-kr-macmini-runtime.tar.gz`, and `.build/baseball-live-kr-backend-macos`. Full tar packaging requires a built macOS app bundle, which is absent in this worktree. |

## Remove-AI-Slops / Overfit Matrix

| Category | Result | Notes |
| --- | --- | --- |
| Obvious comments | PASS | No explanatory filler comments were added to code. Shell scripts remain direct command flow. |
| Over-defensive code | PASS | No fallback to old app bundle paths remains in `scripts/package-macmini-runtime.sh` or `scripts/run-macos-app-with-packaged-backend.sh`; this removes legacy defensive compatibility rather than adding it. |
| Excessive complexity | PASS | The implementation is direct rename/path plumbing. No new nested conditionals, variant chains, or complex boolean expressions were added. |
| Needless abstraction | PASS | No helper abstractions or wrapper functions were introduced. |
| Boundary violations | PASS | Backend env parsing remains in `backend-spike/src/db/database.ts`; package/run scripts own package paths; docs own documentation. |
| Dead code | PASS | Final legacy app path fallbacks were removed from package/run scripts. |
| Duplication | PASS | New names are repeated only where they are externally visible package/env/path constants in scripts/docs/tests. No reusable helper was warranted for shell constants. |
| Performance equivalence | N/A | T3 changed names/paths only; no runtime algorithm was changed. |
| Missing tests | PASS | Existing test suite covers DB enable/path behavior; `rawSourceRepository.test.ts` adds a malformed env probe for blank DB path and invalid enabled value. |
| Oversized modules | PASS with documented prose exception | Edited TypeScript files are at or below 245 pure LOC; `baseball-live-kr-deployment-plan.md` is 327 pure LOC but is a prose planning artifact, not source code. |
| Overfit test check | PASS | The added test asserts observable env behavior (`resolveDatabasePath`, `isDatabaseDisabled`) and would fail if blank path fallback or invalid enable handling changed. It does not assert on implementation-only strings beyond public env names. |
| Deletion-only test check | PASS | No tests were weakened or removed; the new test covers behavior introduced by env rename parsing. |

## Programming Criteria Matrix

| Criterion | Result | Evidence |
| --- | --- | --- |
| Strict TypeScript build | PASS | `npm-build.txt` records `tsc -p tsconfig.build.json` passing. |
| Tests green | PASS | `npm-test.txt` records 25 files and 91 tests passing. |
| No escape hatches | PASS | `typescript-no-excuse-fallback-rg.txt` has no matches for `as any`, `as unknown`, `@ts-ignore`, `@ts-expect-error`, `: any`, non-null assertions, enums, or throw-literal patterns in edited TS files. |
| Canonical no-excuse script status | BLOCKED with fallback | `typescript-no-excuse-audit-failed.txt` records the skill-cache script failing to resolve `typescript`; fallback grep audit and `tsc` build were used instead. |
| Parse/validate at boundary | PASS | Env strings are normalized only in `resolveDatabasePath` / `isDatabaseDisabled`; callers receive resolved path or disabled state. |
| Single responsibility | PASS | `database.ts` owns DB path/open/disable state; tests own repository and env behavior; scripts own package/runtime commands; docs own instructions. |
| Variant discrimination | N/A | No tagged union or enum variant logic was touched. |
| Defensive layer review | PASS | Old app bundle fallbacks were removed; blank DB path fallback remains intentional and covered by test. |
| One-off helper review | PASS | No new one-off helper functions were introduced. |
| LOC/code-smell review | PASS | `changed-file-loc.txt` records edited TS files at or below 245 pure LOC; no source file exceeds the 250 pure LOC ceiling. |

## Manual QA Matrix

| Scenario | Command / Artifact | Expected | Actual |
| --- | --- | --- | --- |
| RED baseline | `red-baseline-legacy-names.txt` | Old `kbo-live-backend-macos`, `KBO_DB_`, and `KboLiveApp` names appear before fix. | PASS |
| Backend tests | `npm --prefix backend-spike test`, `npm-test.txt` | Test suite passes. | PASS: 25 files, 91 tests. |
| Backend build | `npm --prefix backend-spike run build`, `npm-build.txt` | TypeScript build passes. | PASS |
| Backend package | `scripts/package-backend-macos.sh`, `package-backend-macos-rerun.txt` | `.build/baseball-live-kr-backend-macos` is produced. | PASS |
| Package file list | `package-file-list-rerun.txt` | Contains `.data/baseball-live-kr.sqlite`, `run-backend.command`, README, dist, package files. | PASS |
| Generated file inspection | `package-generated-inspection-rerun.txt` | `run-backend.command` and README mention `BASEBALL_LIVE_KR_DB_*` and `baseball-live-kr.sqlite`; no old DB names. | PASS |
| Packaged runtime health | `packaged-backend-health.txt` | Packaged backend starts and `/health` responds OK. | PASS |
| Mac mini package naming | `package-macmini-runtime-name-probe.txt` | Helper expects `BaseballLiveKR.app`, `baseball-live-kr-macmini-runtime.tar.gz`, and new backend package directory. | PASS |
| Full Mac mini tar packaging | `package-macmini-runtime-name-probe.txt` | Requires a built macOS app bundle. | N/A: worktree lacks `.xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`; script correctly fails with the new expected path. |
| Residual old names | `residual-old-t3-names.txt` and `review-matrix-lightweight-checks.txt` | No T3-owned legacy backend/package/env names remain. | PASS with D-owned asset script exception. |
| Cleanup | `cleanup-receipt.txt` | No packaged backend process remains on QA port. | PASS |

## Final Review

- Safety: PASS. Evidence-only follow-up; no product files changed.
- Behavior: PASS. Original `61e6d5d` behavior remains covered by tests/build/package health evidence.
- Quality: PASS. Explicit slop/programming/manual-QA coverage is now documented in this matrix.
- Remaining limitation: full Mac mini tar packaging remains deferred until a built `BaseballLiveKR.app` exists in the worktree.
