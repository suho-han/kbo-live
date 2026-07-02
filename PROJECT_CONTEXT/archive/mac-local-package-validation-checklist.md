# KBO Live Mac Local Package Validation Checklist

작성일: 2026-06-10
상태: Working v0.1
기준 시간: 2026-06-10 20:37:52 KST
대상 환경: 로컬 Mac + Xcode 16 이상 + Swift 6 toolchain

## 1. 목적

`Packages/BaseballLiveKRCore` 와 `Packages/BaseballLiveKRDesignSystem` 을 **Mac에서 실제로 build/test 검증**할 때 바로 따라 할 수 있는 체크리스트를 제공한다.

이 문서는 현재 Linux 호스트에서 `swift` 명령이 없어 실행하지 못한 검증을, Mac에서 빠르게 재현하고 통과 여부를 기록하기 위한 문서다.

---

## 2. 현재 전제

현재 저장소에서 이미 준비된 것:
- `Packages/BaseballLiveKRCore` 존재
- `Packages/BaseballLiveKRDesignSystem` 존재
- `BaseballLiveKRCore` 에 fixture/decode/mapper/projection 테스트 초안 존재
- 최근 수정 사항:
  - `GameProjectionFormatter` 중복 상태 문자열 제거
  - `GameDTOMapper` startTime 파싱 보강
  - `OutCountView` 3 outs 허용

아직 미검증인 것:
- `swift build`
- `swift test`
- SwiftUI/SwiftPM 실제 compile 결과

---

## 3. 빠른 성공 기준

Mac에서 아래가 모두 통과하면 1차 성공으로 본다.

1. `swift --version` 이 정상 출력된다.
2. `Packages/BaseballLiveKRCore` 에서 `swift build` 성공
3. `Packages/BaseballLiveKRCore` 에서 `swift test` 성공
4. `Packages/BaseballLiveKRDesignSystem` 에서 `swift build` 성공
5. 가능하면 Xcode에서 두 패키지가 열리고 indexing error가 없다.

---

## 4. 실행 순서

### Step 1. 저장소 최신화

```bash
cd /path/to/kbo-live
git pull --ff-only origin main
git log --oneline -3
```

기대 결과:
- 최신 커밋에 아래가 보여야 함
  - `b6ae191 docs(plan): refine Apple-native MVP decisions`
  - `73e2cc4 fix(design-system): allow three outs in out count view`
  - `28338dc fix(core): align start time contract and dedupe menu text`

### Step 2. Swift toolchain 확인

```bash
swift --version
xcodebuild -version
```

기대 결과:
- `swift` 버전 출력
- `Xcode` 버전 출력

실패 시:
- Xcode Command Line Tools 선택 확인
```bash
xcode-select -p
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Step 3. Core package build

```bash
cd /path/to/kbo-live/Packages/BaseballLiveKRCore
swift package reset
swift build
```

기대 결과:
- build success
- package manifest/load error 없음

확인 포인트:
- `GameDTOMapper.swift`
- `GameProjectionFormatter.swift`
- fixture resource 처리

### Step 4. Core package test

```bash
cd /path/to/kbo-live/Packages/BaseballLiveKRCore
swift test
```

기대 결과:
- 전체 테스트 pass

특히 확인할 테스트 의미:
- fixture decode 정상
- `startTime` basic ISO 파싱 정상
- extended ISO 파싱 정상
- menu bar status token dedupe 정상
- live activity / widget / menu bar projection mapper 정상

### Step 5. DesignSystem package build

```bash
cd /path/to/kbo-live/Packages/BaseballLiveKRDesignSystem
swift package reset
swift build
```

기대 결과:
- build success

특히 확인할 포인트:
- `OutCountView(outs: 3)` compile 문제 없음
- token/component import 문제 없음

### Step 6. 선택 검증: Xcode에서 package 열기

Finder 또는 Xcode로 아래 중 하나를 연다.
- `Packages/BaseballLiveKRCore/Package.swift`
- `Packages/BaseballLiveKRDesignSystem/Package.swift`

기대 결과:
- indexing error 없음
- preview/build diagnostics 에 즉시 syntax error 없음

---

## 5. 권장 실행 명령 묶음

### Core 한 번에
```bash
cd /path/to/kbo-live/Packages/BaseballLiveKRCore && swift package reset && swift build && swift test
```

### DesignSystem 한 번에
```bash
cd /path/to/kbo-live/Packages/BaseballLiveKRDesignSystem && swift package reset && swift build
```

### 둘 다 순차 실행
```bash
cd /path/to/kbo-live/Packages/BaseballLiveKRCore && swift package reset && swift build && swift test && \
cd /path/to/kbo-live/Packages/BaseballLiveKRDesignSystem && swift package reset && swift build
```

---

## 6. 실패 시 우선 확인할 지점

### A. `GameDTOMapper` 관련 컴파일/테스트 실패

확인 파일:
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Mappers/GameDTOMapper.swift`
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/TodayGamesResponseDTOTests.swift`
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/Fixtures/today-games-response.json`

의심 포인트:
- `ISO8601DateFormatter` 옵션 조합 차이
- fixture resource bundle 로딩 문제
- Swift 6 toolchain에서 formatter option 경고/에러

### B. `GameProjectionFormatter` 관련 테스트 실패

확인 파일:
- `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/Formatting/GameProjectionFormatter.swift`
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/ProjectionMapperTests.swift`

의심 포인트:
- dedupe 로직이 기대 문자열 순서를 바꾸는지
- `LIVE`, `지연`, `취소` 상태의 secondary text 기대값 불일치

### C. `OutCountView` 관련 compile 실패

확인 파일:
- `Packages/BaseballLiveKRDesignSystem/Sources/BaseballLiveKRDesignSystem/Components/OutCountView.swift`

의심 포인트:
- 단순 clamp 수정 자체보다, 상위 preview/호출부가 0...2만 가정하고 있을 가능성
- SwiftUI import / token symbol resolution 문제

### D. fixture resource 로딩 실패

확인 파일:
- `Packages/BaseballLiveKRCore/Package.swift`
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/FixtureLoader.swift`
- `Packages/BaseballLiveKRCore/Tests/BaseballLiveKRCoreTests/Fixtures/today-games-response.json`

의심 포인트:
- `.process("Fixtures")` 처리
- test bundle 경로 차이

---

## 7. 통과 후 바로 이어갈 다음 액션

패키지 검증이 통과하면 바로 다음 순서:

1. `KboLive.xcworkspace` / app targets 생성
2. local package 2개를 iOS/macOS/widget/activity target에 연결
3. mock 데이터 기반 첫 화면 build
4. Home card / Small Widget / Menu Bar / Live Activity sample 연결

---

## 8. 실행 결과 기록 템플릿

Mac에서 검증 후 아래 형식으로 기록하면 된다.

```text
[Mac local package validation]
- swift --version: PASS/FAIL
- xcodebuild -version: PASS/FAIL
- BaseballLiveKRCore swift build: PASS/FAIL
- BaseballLiveKRCore swift test: PASS/FAIL
- BaseballLiveKRDesignSystem swift build: PASS/FAIL
- notes:
  - (에러 요약 또는 특이사항)
```

---

## 9. 현재 결론

이 체크리스트의 목적은 **Mac에서 10분 안에 shared Swift packages의 실제 생존 여부를 판정**하는 것이다.

지금 기준 가장 중요한 판정 포인트는 아래 3개다.
- `BaseballLiveKRCore` 가 fixture/test까지 실제로 도는가
- `GameDTOMapper` startTime 파싱 보강이 Swift toolchain에서도 문제없는가
- `OutCountView` 수정이 DesignSystem build를 깨지 않는가
