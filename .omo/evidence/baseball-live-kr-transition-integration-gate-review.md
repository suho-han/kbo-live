# Baseball LIVE KR Transition Integration Gate Re-review

recommendation: REJECT

## originalIntent

Integrate the approved T1-T4 Baseball LIVE KR transition work into `codex/baseball-live-kr-transition-integration`, keep T1-T4 heads plus T5 commits reachable from `HEAD`, and demonstrate that the branch uses current Baseball LIVE KR project/package/scheme/runtime names across build, release, docs, and verification surfaces.

## desiredOutcome

The user should receive a branch that builds and verifies as Baseball LIVE KR, exposes only BaseballLiveKR Xcode schemes, rejects release artifacts that contain official visual asset filenames or uninspected targets, has clean branch diff hygiene, and has no stale active documentation that would tell a developer to use old `KBO Live` / `KboLive*` project, package, scheme, app, or env names.

## userOutcomeReview

The requested fresh probes mostly pass: full diff whitespace is clean, the exact six-file broad-doc scan returns no matches, the expected T1-T4/T5 commits are all ancestors of `HEAD`, the generated project lists the BaseballLiveKR schemes, and the release asset verifier positive/negative probes behave correctly.

I cannot approve because a stricter pass over documents that `PROJECT_CONTEXT/README.md` itself lists as "current reference docs" still finds old `KBO Live` / `KboLive*` names and stale command paths. This is the same blocker class as the prior rejection: active docs can still mislead future work after the rename.

## blockers

1. Active current-reference docs still contain stale names outside the narrower six-file scan.
   - `PROJECT_CONTEXT/README.md` says root `PROJECT_CONTEXT` keeps only current reference docs and lists these files under "현재 참고 문서".
   - Command run:

```bash
rg -n 'KboLiveApp\.xcodeproj|KboLivemacOS|KboLiveiOS|KboLiveWidgetExtension|KboLiveCore|KboLiveDesignSystem|KboLiveFeatures|KBO_LIVE_BASE_URL|KBO Live' PROJECT_CONTEXT/forward-development-roadmap.md PROJECT_CONTEXT/backend-spike-plan.md PROJECT_CONTEXT/backend-spike-results.md PROJECT_CONTEXT/team-player-records-db-plan.md PROJECT_CONTEXT/kbo-data-quality-regression-plan.md PROJECT_CONTEXT/app-productization-roadmap.md PROJECT_CONTEXT/macos-release-operations.md PROJECT_CONTEXT/mvp-stability-checklist.md PROJECT_CONTEXT/liquid-glass-toss-design-plan.md PROJECT_CONTEXT/kbo-data-source-research.md PROJECT_CONTEXT/shared-dto-draft.md PROJECT_CONTEXT/swiftui-component-structure.md PROJECT_CONTEXT/kbo-data-validation-checklist.md
```

   - Exit: `0`
   - Evidence:
     - `PROJECT_CONTEXT/forward-development-roadmap.md:1`: `# KBO Live Forward Development Roadmap`
     - `PROJECT_CONTEXT/forward-development-roadmap.md:37`: `KboLiveCore`
     - `PROJECT_CONTEXT/forward-development-roadmap.md:53`: `KboLivemacOS`
     - `PROJECT_CONTEXT/forward-development-roadmap.md:131`: `KboLiveApp/KboLiveApp.xcodeproj`
     - `PROJECT_CONTEXT/kbo-data-validation-checklist.md:82`: `cd Packages/KboLiveCore`
     - `PROJECT_CONTEXT/shared-dto-draft.md:1`: `# KBO Live Shared DTO Draft`
     - `PROJECT_CONTEXT/shared-dto-draft.md:103`: `Packages/KboLiveCore/Sources/KboLiveCore/DTO/`
     - `PROJECT_CONTEXT/liquid-glass-toss-design-plan.md:85-87`: old `Packages/KboLiveDesignSystem/...` paths
     - `PROJECT_CONTEXT/backend-spike-plan.md:1`: `# KBO Live Backend Spike Plan`
   - User impact: these docs are not under `PROJECT_CONTEXT/archive/` and are advertised as current references, so they remain an active stale-instruction surface.

## requestedProbeEvidence

- Command:

```bash
git diff --check $(git merge-base main HEAD)..HEAD
```

  - Exit: `0`
  - Output: no output.

- Command:

```bash
rg -n 'KboLiveApp\.xcodeproj|KboLivemacOS|KboLiveiOS|KboLiveWidgetExtension|KboLiveCore|KboLiveDesignSystem|KboLiveFeatures|KBO_LIVE_BASE_URL|KBO Live' PROJECT_CONTEXT/README.md PROJECT_CONTEXT/xcode-project-structure.md PROJECT_CONTEXT/live-activity-verification.md PROJECT_CONTEXT/production-backend-strategy.md PROJECT_CONTEXT/widget-live-activity-personalization-plan.md DESIGN.md
```

  - Exit: `1`
  - Output: no matches.

- Command:

```bash
for c in 1c83b3f fc0e231 f4d8863 df90756 7fbb491 29a0945 151aa80; do git merge-base --is-ancestor "$c" HEAD && echo "$c ancestor-of-HEAD" || echo "$c NOT-ancestor-of-HEAD"; done
```

  - Exit: `0`
  - Output:
    - `1c83b3f ancestor-of-HEAD`
    - `fc0e231 ancestor-of-HEAD`
    - `f4d8863 ancestor-of-HEAD`
    - `df90756 ancestor-of-HEAD`
    - `7fbb491 ancestor-of-HEAD`
    - `29a0945 ancestor-of-HEAD`
    - `151aa80 ancestor-of-HEAD`

- Command:

```bash
xcodebuild -list -project BaseballLiveKR.xcodeproj
```

  - Exit: `0`
  - Evidence: targets and schemes are `BaseballLiveKRWidgetExtension`, `BaseballLiveKRiOS`, and `BaseballLiveKRmacOS`.

- Release asset verifier positive probe:

```bash
tmp=$(mktemp -d); ./scripts/verify-release-assets.sh "$tmp"; rc=$?; rm -rf "$tmp"; echo "exit=$rc"
```

  - Output: `No official visual asset filenames found in release/staged artifacts.` and `exit=0`.

- Release asset verifier official-asset negative probe:

```bash
tmp=$(mktemp -d); touch "$tmp/HH.png"; ./scripts/verify-release-assets.sh "$tmp"; rc=$?; rm -rf "$tmp"; echo "exit=$rc"
```

  - Output includes the temp `HH.png`, `Official visual asset risk found in release/staged artifacts.`, and `exit=1`.

- Release asset verifier missing-target negative probe:

```bash
./scripts/verify-release-assets.sh /tmp/definitely-missing-t5-rereview-path; echo "exit=$?"
```

  - Output includes `Missing release/staged artifact target: /tmp/definitely-missing-t5-rereview-path`, `One or more explicit release/staged artifact targets were missing.`, and `exit=2`.

## slopAndProgrammingReview

Direct remove-ai-slops pass: no unresolved production-code slop blocker found in the inspected final diff surfaces. The verifier probes are behavioral, not removal-only; the remediation added no new tests; the sampled changed source/script files are below the 250 pure LOC ceiling except pre-existing large Swift view files not expanded by this remediation. No `as any`, `@ts-ignore`, or `@ts-expect-error` appears in the reviewed remediation evidence.

Report coverage check: `.omo/evidence/baseball-live-kr-transition/T5-final-integration/gate-remediation-review.md` explicitly covers code review, remove-ai-slops/overfit taxonomy, excessive/useless tests, deletion/removal-only tests, tautological tests, implementation-mirroring tests, unnecessary extraction/parsing/normalization, and programming criteria. T1/T3/T4 review artifacts also include slop/programming matrices. Report coverage exists, but it does not overcome the remaining active-doc blocker above.

## checkedArtifactPaths

- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/integration-summary.md`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/manual-qa-matrix.md`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/gate-remediation-review.md`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/remediation/broader-current-doc-stale-name-search.txt`
- `.omo/evidence/baseball-live-kr-transition/T5-final-integration/remediation/full-working-diff-check-after-broader-docs.txt`
- `.omo/evidence/baseball-live-kr-transition/T1-project-swift/code_review_programming_slop_audit.txt`
- `.omo/evidence/baseball-live-kr-transition/T3-backend-scripts-docs/code-review-manual-qa-matrix.md`
- `.omo/evidence/baseball-live-kr-transition/T4-rights-release-qa/implementation-review.md`
- `PROJECT_CONTEXT/README.md`
- `PROJECT_CONTEXT/xcode-project-structure.md`
- `PROJECT_CONTEXT/live-activity-verification.md`
- `PROJECT_CONTEXT/production-backend-strategy.md`
- `PROJECT_CONTEXT/widget-live-activity-personalization-plan.md`
- `PROJECT_CONTEXT/macos-release-operations.md`
- `PROJECT_CONTEXT/mvp-stability-checklist.md`
- `PROJECT_CONTEXT/forward-development-roadmap.md`
- `PROJECT_CONTEXT/backend-spike-plan.md`
- `PROJECT_CONTEXT/backend-spike-results.md`
- `PROJECT_CONTEXT/team-player-records-db-plan.md`
- `PROJECT_CONTEXT/liquid-glass-toss-design-plan.md`
- `PROJECT_CONTEXT/kbo-data-source-research.md`
- `PROJECT_CONTEXT/shared-dto-draft.md`
- `PROJECT_CONTEXT/swiftui-component-structure.md`
- `PROJECT_CONTEXT/kbo-data-validation-checklist.md`
- `DESIGN.md`
- `BaseballLiveKR.xcodeproj/project.pbxproj`
- `project.yml`
- `scripts/verify-release-assets.sh`
- `scripts/kbo-live.sh`
- `scripts/package-backend-macos.sh`
- `scripts/package-macmini-runtime.sh`
- `scripts/run-macos-app-with-packaged-backend.sh`
- `scripts/deploy-macmini-runtime.sh`
- `scripts/verify-local.sh`

## exactEvidenceGaps

- The committed T5 remediation evidence records the six-file broad-doc scan as clean, but it does not account for other docs that `PROJECT_CONTEXT/README.md` classifies as current references.
- Current-reference docs outside the exact scan still contain old product/package/scheme/path names, including stale `Packages/KboLiveCore` and `KboLiveApp.xcodeproj` guidance.
- Because active docs remain stale, the user-visible rename/remediation outcome is not fully satisfied even though the requested narrow probes pass.
