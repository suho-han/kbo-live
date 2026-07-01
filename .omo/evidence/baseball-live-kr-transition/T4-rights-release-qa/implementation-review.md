# T4 Implementation Review

Reviewed files:

- `project.yml`
- `KboLiveApp.xcodeproj/project.pbxproj`
- `KboLiveApp/Shared/AppSettingsView.swift`
- `Packages/KboLiveDesignSystem/Sources/KboLiveDesignSystem/Components/TeamBadgeView.swift`
- `Packages/KboLiveFeatures/Sources/KboLiveFeatures/TodayGames/TodayGamesView.swift`
- `scripts/verify-release-assets.sh`
- `PROJECT_CONTEXT/macos-release-operations.md`

Findings:

- Official runtime image loaders were removed from the edited SwiftUI surfaces. The replacement UI uses `Text` initials inside owned rounded color shapes.
- `project.yml` is the durable source of truth for generated project resources and now excludes all three official asset directories: `TeamLogos/**`, `TeamWordmarks/**`, and `TeamBrandAssets/**`.
- The checked-in baseline `KboLiveApp.xcodeproj` was also cleaned so this worktree can build and inspect a clean app bundle. Per leader coordination, that generated-project edit is integration-obsolete because T1 replaces it with `BaseballLiveKR.xcodeproj`; the equivalent durable exclusion is the `project.yml` change.
- `scripts/verify-release-assets.sh` checks staged/built filesystem paths and archive member names for official visual asset filenames. It fails on injected filesystem and tar archive probes, fails explicit missing artifact targets, and fails default runs that inspect zero existing release/staged roots.
- Notarization readiness is documented as a credentialed procedure rather than claimed as executed. The procedure and pre-release checklist were checked against the current build product name: `BaseballLiveKR.app`, with the notarization zip parameterized as `.build/transfer/${APP_PRODUCT_NAME}.zip`.

Slop and safety coverage:

- No `as any`, `@ts-ignore`, or `@ts-expect-error` style suppressions were introduced.
- No official team mark was replaced by a static mock image or screenshot.
- No package output naming was changed in T4; that remains C/backend-scripts-docs ownership.
- Excessive or useless tests: no new product tests were added; verification uses focused existing Swift package tests plus release artifact probes.
- Deletion-only tests: no tests were deleted or weakened.
- Tautological tests: the release verifier is checked against real negative probes that contain `TeamLogos/HH.png` in both filesystem and tar archive form, so it does not only assert its own success path.
- Implementation-mirroring tests: verifier probes inspect release/staged artifact paths and archive member names, not Swift implementation details or view internals.
- Unnecessary extraction/parsing/normalization: no new parsers or abstractions were introduced for UI fallback rendering; verifier state is limited to target existence, inspected-root count, bounded path/name matching, and whitespace cleanup in the captured xcodebuild evidence log.
- Overfit behavior: `scripts/verify-release-assets.sh` covers the official asset directory names, generic logo/wordmark/emblem/mascot terms, and current team-ID PNG names across directories and archives rather than a single built-app path. It also proves caller error cases instead of assuming a specific existing build layout.
- Misleading success output: follow-up probes cover explicit missing targets, explicit missing plus clean existing target, and a copied-script default run with zero existing roots. All now fail with `exit_code=2` instead of printing the clean success message.
- `remove-ai-slops` was not invoked as a separate cleanup skill because this was a narrow T4 implementation, but the diff was explicitly checked for dead image-loader fallback paths, stale references, fake success-only verification, unchecked archive contents, missing artifact false-success output, and the criteria above.
- `programming` skill is not applicable by its trigger list because the edited code is Swift and shell/docs, not `.py`, `.rs`, `.ts`, `.tsx`, or `.go`; the Swift package tests and macOS build were used instead.

Verification summary:

- `swift test --package-path Packages/KboLiveDesignSystem`: PASS
- `swift test --package-path Packages/KboLiveFeatures`: PASS
- `xcodebuild -project KboLiveApp.xcodeproj -scheme KboLivemacOS -destination 'platform=macOS' -derivedDataPath .xcode/DerivedData CODE_SIGNING_ALLOWED=NO build`: PASS
- `./scripts/verify-release-assets.sh .xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`: PASS
- `./scripts/verify-release-assets.sh`: PASS after inspecting existing default release roots
- `./scripts/verify-release-assets.sh /tmp/definitely-missing-t4-review-path`: FAILS EXPECTED with exit code 2
- `./scripts/verify-release-assets.sh /tmp/definitely-missing-t4-review-path .xcode/DerivedData/Build/Products/Debug/BaseballLiveKR.app`: FAILS EXPECTED with exit code 2
- copied-script default zero-root probe: FAILS EXPECTED with exit code 2
- `rg -n 'KboLiveApp\.(app|zip)' PROJECT_CONTEXT/macos-release-operations.md`: PASS with no matches
- `rg -n 'BaseballLiveKR\.app|APP_PRODUCT_NAME=BaseballLiveKR|APP_ZIP' PROJECT_CONTEXT/macos-release-operations.md`: PASS with current product/archive references
- `git diff --check 43b4445^ 43b4445`: initially failed on trailing whitespace in `green/xcodebuild-macos-debug.txt`; this follow-up evidence-only commit normalizes that log.
- `git diff --check 43b4445^ HEAD`: PASS after follow-up normalization.
