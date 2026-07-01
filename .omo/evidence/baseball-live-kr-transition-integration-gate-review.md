# Baseball LIVE KR Transition Integration Gate Review

recommendation: REJECT

## originalIntent

Integrate the approved T1-T4 Baseball LIVE KR transition work into `codex/baseball-live-kr-transition-integration` at `7fbb491`, then provide final T5 evidence that the integrated branch builds, tests, packages, verifies release assets, cleans up processes, and contains no stale product/project/script names or misleading success evidence.

## desiredOutcome

The user should receive an integrated Baseball LIVE KR branch where the approved member commits are reachable, all user-facing build/package/release instructions use current names, release asset verification fails on missing or zero-inspection targets, branch diff hygiene is clean, and T5 evidence includes code review/slop coverage, manual QA, adversarial checks, cleanup, and verification outputs.

## userOutcomeReview

The branch integrates the T1-T4 heads and has strong build/test/package evidence, but it does not yet satisfy the user-visible completion outcome. Active release operations documentation still gives old `KboLiveApp.xcodeproj` / `KboLivemacOS` commands and old package artifact names that no longer match the integrated branch. The full branch diff fails `git diff --check`, while T5 records a green diff-check artifact without enough command context to support that claim for the integrated branch. T5 also lacks a code-review/slop report for the final integration diff.

## blockers

1. Full branch diff hygiene fails.
   - Command run: `git diff --check $(git merge-base main HEAD)..HEAD`
   - Exit: `2`
   - Evidence:
     - `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/npm-build.txt:4: new blank line at EOF.`
     - `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/npm-test.txt:112: new blank line at EOF.`
     - `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/typescript-no-excuse-fallback-rg.txt:3: new blank line at EOF.`
     - `baseball-live-kr-deployment-plan.md:3-8: trailing whitespace.`
   - Evidence gap: T5 `green/git-diff-check.txt` contains only `git_diff_check_exit=0` and does not show the checked range. It is not sufficient evidence for whole-branch hygiene.

2. T5 final integration evidence lacks the required code-review/slop coverage.
   - Command run: `rg -n "code review|Remove-AI-Slops|Overfit|programming|tautological|implementation-mirroring|deletion-only|excessive|useless tests|unnecessary extraction" .omo/evidence/baseball-live-kr-transition/T5-final-integration`
   - Exit: `1`, no matches.
   - Evidence gap: T3 and T4 member evidence include review/slop matrices, but T5 does not contain an integration-level code review report and does not explicitly cover the `remove-ai-slops` overfit/slop criteria for final conflict resolutions and residual fixes.

3. Active release documentation still contains stale/broken project, scheme, and package names.
   - File: `PROJECT_CONTEXT/macos-release-operations.md`
   - Stale evidence:
     - line 7: `KboLivemacOS`
     - lines 14-15: `xcodebuild -project KboLiveApp.xcodeproj` and `-scheme KboLivemacOS`
     - line 41: `.build/transfer/kbo-live-macmini-runtime.tar.gz`
     - line 47: `.build/kbo-live-backend-macos`
     - lines 101-102: release build still uses `KboLiveApp.xcodeproj` / `KboLivemacOS`
     - line 154: pre-release checklist still says `KboLivemacOS` build.
   - User impact: the integration branch no longer has `KboLiveApp.xcodeproj`; current schemes are `BaseballLiveKRiOS`, `BaseballLiveKRmacOS`, and `BaseballLiveKRWidgetExtension`.

4. T5 adversarial evidence for default zero roots is incomplete as an artifact.
   - Artifact: `.omo/evidence/baseball-live-kr-transition/T5-final-integration/adversarial/verify-release-assets-default-zero-roots.txt`
   - It contains only `No release/staged artifact roots exist to inspect.` and no exit code or command context.
   - Direct verification passed: `./scripts/verify-release-assets.sh /tmp/definitely-missing-t5-gate-review-path` exits `2` and prints the expected missing-target error. This means the script behavior is likely correct, but the T5 artifact is incomplete.

## checkedArtifactPaths

- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/integration-summary.md`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/manual-qa-matrix.md`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/cleanup-receipt.md`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/evidence-files.txt`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/green/*`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/adversarial/verify-release-assets-default-zero-roots.txt`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/manual-qa/*`
- `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/code-review-manual-qa-matrix.md`
- `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/residual-old-t3-names.txt`
- `.omo/evidence/baseball-live-kr-transition/T4-rights-release-qa/implementation-review.md`
- `.omo/evidence/baseball-live-kr-transition/T4-rights-release-qa/notepad.md`
- `PROJECT_CONTEXT/macos-release-operations.md`
- `docs/dev.md`
- `scripts/verify-release-assets.sh`
- `BaseballLiveKR.xcodeproj/project.pbxproj`
- `project.yml`
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/BaseballLiveKREnvironment.swift`
- `Packages/BaseballLiveKRFeatures/Sources/BaseballLiveKRFeatures/TodayGames/MyTeamSelectionStore.swift`
- `backend-spike/src/db/database.ts`
- `backend-spike/tests/rawSourceRepository.test.ts`

## directVerification

- T1-T4 approved heads are reachable from `HEAD`:
  - `1c83b3f`: ancestor exit `0`
  - `fc0e231`: ancestor exit `0`
  - `f4d8863`: ancestor exit `0`
  - `df90756`: ancestor exit `0`
- T5 build/test evidence shows passing Swift, npm, xcodegen, xcodebuild, package, health, and release-asset checks.
- Direct missing-target verifier check exits `2`, so the missing-target false-success production issue appears fixed.
- Direct official asset reference check finds only intended excludes/source-asset tooling and verifier patterns; no generated project release resource references were found.
- Direct slop/programming pass found no oversized inspected source files in the sampled final-diff code: `database.ts` 45 pure LOC, `rawSourceRepository.test.ts` 63, `verify-release-assets.sh` 92, `BaseballLiveKREnvironment.swift` 83, `MyTeamSelectionStore.swift` 40. The blocker is absent T5 report coverage plus unresolved evidence/docs hygiene, not a newly found production extraction/parsing/normalization smell in those sampled files.

## exactEvidenceGaps

- No T5 code-review report artifact.
- No T5 `remove-ai-slops` / overfit matrix covering excessive/useless tests, deletion-only tests, tautological tests, implementation-mirroring tests, and unnecessary extraction/parsing/normalization for the final integration diff.
- T5 `git-diff-check.txt` lacks command/range output and conflicts with the failing full-branch `git diff --check`.
- T5 zero-roots adversarial artifact lacks exit code.
- Active `PROJECT_CONTEXT/macos-release-operations.md` remains stale after integration and contradicts current project/scheme/package names.
