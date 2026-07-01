# T5 gate remediation review

## Scope

This follow-up covers the final integration branch after gate rejection on stale active docs, full-branch whitespace hygiene, incomplete zero-root verifier evidence, and missing T5 final-diff review coverage.

## Code review

- The integration merge commits keep approved T1-T4 work reachable and resolve conflicts by current ownership: T1 owns project/package/module names, T2 owns storage/runtime defaults, T3 owns backend/package scripts, and T4 owns release asset exclusion.
- `BaseballLiveKR.xcodeproj/project.pbxproj` is generated from `project.yml`; the final integration regeneration removes stale `TeamLogos` team-ID PNG resource references rather than hand-editing release resources.
- `scripts/kbo-live.sh` clears `BASEBALL_LIVE_KR_BASE_URL`, matching the renamed runtime setting used by the integrated app.
- `backend-spike/tests/contract.test.ts` points at the renamed Swift fixture path under `Packages/BaseballLiveKRCore`, preserving the backend/Swift contract test instead of weakening it.
- Active release/stability docs now use `BaseballLiveKR.xcodeproj`, `BaseballLiveKRmacOS`, `BaseballLiveKRiOS`, `Packages/BaseballLiveKR*`, `.build/baseball-live-kr-backend-macos`, and `.build/transfer/baseball-live-kr-macmini-runtime.tar.gz`.

## Remove-AI-slops / overfit-test taxonomy

- Excessive or useless tests: no new tests were added for the remediation; existing package, backend, and xcodebuild verification artifacts are reused.
- Deletion-only tests: none added.
- Removal-only tests: none added; release asset checks inspect generated/built artifacts and adversarial missing targets rather than merely asserting removed strings.
- Tautological tests: none added; checks run real commands (`swift test`, `npm test`, `xcodebuild`, `verify-release-assets.sh`, packaged backend `/health`).
- Implementation-mirroring tests: none added; residual scans and verifier checks validate observable names/artifacts, not internal implementation structure alone.
- Unnecessary extraction/parsing/normalization: no new abstractions were introduced. Remediation edits are direct doc updates, evidence hygiene, and existing script verification.
- Misleading success output: zero-root release asset evidence now records the command and exit code; diff-check evidence records the checked range and exit code.

## Programming criteria

- No `as any`, `@ts-ignore`, or `@ts-expect-error` was introduced.
- No failing tests were deleted or weakened.
- No production TypeScript or Swift behavior changed in the remediation beyond existing final integration fixes already verified in T5.
- Full branch whitespace check is clean in the working remediation state and is expected to be clean for `$(git merge-base main HEAD)..HEAD` after the follow-up commit lands.

## Manual QA criteria

- The current app project list exposes only the `BaseballLiveKR` schemes.
- The built macOS app release asset verifier passed against `.xcode/DerivedData-macOS/Build/Products/Debug/BaseballLiveKR.app`.
- The packaged backend health check returned `{"ok":true,...}` on the manual QA port and cleanup probes show no leaked backend/xcode/swift test process.

## Conclusion

The gate rejection was valid. The remediation fixes active stale instructions, branch diff hygiene, and evidence completeness without changing product behavior or amending prior commits.
