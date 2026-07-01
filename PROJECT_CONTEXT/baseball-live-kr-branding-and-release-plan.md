# Baseball LIVE KR — 브랜딩 · 네이밍 · 배포 정책

> 이 문서는 스토어 출시용 **Baseball LIVE KR** 브랜드와 배포 식별자를 고정하기 위한 정책 기준서다.
> KBO 상표를 앱명·식별자·아이콘·패키지명에서 제거하고, `suhohan.kr` 기준의 `kr.suhohan.*` reverse-DNS 식별자로 통일한다.

## 현재 반영 범위 (중요)

이 문서는 **전체 배포 정책**(iOS/Android/백엔드/MCP/Skill 포함)을 기록한다. 현재 iOS/macOS/Widget, Swift 모듈, backend companion, GitHub repo/runtime URL, App Group, release asset policy는 Baseball LIVE KR 기준으로 반영되어 있다.

| 항목 | 상태 |
| --- | --- |
| 정책 문서화 (본 문서) | ✅ 완료 |
| macOS 표시명 (창 제목/메뉴바/대시보드/홈 헤더 → `Baseball LIVE KR`) | ✅ 완료 |
| macOS 식별자 (`kr.suhohan.baseballlivekr.macos`, PRODUCT_NAME `BaseballLiveKR`) | ✅ 완료 |
| macOS Dock/Finder 표시명 (`CFBundleDisplayName = Baseball LIVE KR`) | ✅ 완료 |
| iOS/Widget Bundle ID · App Group rename | ✅ 완료 |
| 백엔드 URL / `BASEBALL_LIVE_KR_*` 환경변수 rename | ✅ 완료 |
| ATS(`NSAllowsArbitraryLoads`) 제거 | ✅ 완료 |
| Swift 모듈/디렉터리/타입 prefix 리팩터 | ✅ 완료 |
| GitHub repo · backend package/runtime URL rename | ✅ 완료 |
| MCP package명 | ⬜ 미완료 |
| MCP 서버 · Claude Skill 공개 | ⬜ 미완료 (앱 출시 후) |

---

## 1. 최종 배포 매트릭스

| 영역 | 값 |
| --- | --- |
| 제품명 | Baseball LIVE KR |
| 한국어명 | 한국 야구 라이브 |
| 도메인 | suhohan.kr |
| 랜딩 | https://suhohan.kr/baseball-live-kr |
| Privacy | https://suhohan.kr/baseball-live-kr/privacy |
| Support | https://suhohan.kr/baseball-live-kr/support |
| Terms | https://suhohan.kr/baseball-live-kr/terms |
| API | https://api.suhohan.kr/baseball-live-kr |
| MCP | https://mcp.suhohan.kr/baseball-live-kr |
| GitHub | suho-han/baseball-live-kr |
| iOS Bundle ID | kr.suhohan.baseballlivekr.ios |
| macOS Bundle ID | kr.suhohan.baseballlivekr.macos |
| Widget Bundle ID | kr.suhohan.baseballlivekr.ios.widget |
| Android applicationId | kr.suhohan.baseballlivekr |
| Backend package | baseball-live-kr-backend |
| MCP package | baseball-live-kr-mcp |
| Skill | baseball-live-kr |
| SKU | baseball-live-kr |
| App Group | group.kr.suhohan.baseballlivekr |

---

## 2. 네이밍 정책

| 영역 | 권장값 |
| --- | --- |
| 앱 브랜드명 | Baseball LIVE KR |
| 한국어 표시명 | 한국 야구 라이브 |
| App Store 영문명 | Baseball LIVE KR |
| App Store 한국어명 | 한국 야구 라이브 |
| Google Play 영문명 | Baseball LIVE KR |
| Google Play 한국어명 | 한국 야구 라이브 |
| 앱 내부 짧은 표시명 | LIVE KR 또는 야구 라이브 |
| 설명 문구 | Unofficial Korean baseball live scores and schedules. |

- App Store / Google Play 모두 **앱 이름 30자 제한**. `Baseball LIVE KR` 은 한도 내.
- Bundle ID / Android applicationId 는 **최초 업로드 후 변경 불가** → 첫 업로드 전에 확정.
- Google Play 는 브랜드가 원래 대문자가 아니면 제목의 과도한 CAPS 를 제한적으로 본다. `LIVE` 를 브랜드 스타일로 고정하려면 로고·웹사이트에서도 `Baseball LIVE KR` 로 일관 사용. 일관성이 어려우면 Google Play 는 `Baseball Live KR` 이 더 안전.

### KBO 상표 사용 금지 규칙
- 앱명 · Bundle ID · 패키지명 · repo명 · 아이콘 · 스크린샷 · 마케팅 헤드라인에 **`KBO` 사용 금지**.
- `KBO` 는 "한국 프로야구 경기 일정/결과를 보여주는 **비공식** 앱" 처럼 **설명 문구에서만** 제한적으로 사용하고, 반드시 비공식 문구를 함께 표기.

---

## 3. 식별자 정책 (reverse-DNS `kr.suhohan.*`)

`suhohan.kr` 을 기준 도메인으로 삼으므로 식별자는 `kr.suhohan.*` 형태로 통일한다.

| 대상 | 값 |
| --- | --- |
| iOS Bundle ID | kr.suhohan.baseballlivekr.ios |
| macOS Bundle ID | kr.suhohan.baseballlivekr.macos |
| Widget Bundle ID | kr.suhohan.baseballlivekr.ios.widget |
| Android applicationId | kr.suhohan.baseballlivekr |
| App Group | group.kr.suhohan.baseballlivekr |

> App Group 을 rename 하면 `WidgetGameSnapshotStore.swift` 와 iOS/Widget entitlements 3곳을 **동시에** 맞춰야 하며, 기존 공유 UserDefaults 데이터는 마이그레이션되지 않는다.

---

## 4. App Store / Google Play 메타데이터

### App Store
| 필드 | 값 |
| --- | --- |
| App Name (en-US) | Baseball LIVE KR |
| Subtitle (en-US) | Korean Scores & Schedule *(24자, 30자 한도 내)* |
| App Name (ko-KR) | 한국 야구 라이브 |
| Subtitle (ko-KR) | 한국 야구 스코어·일정 |
| Category | Sports |
| Support URL | https://suhohan.kr/baseball-live-kr/support |
| Privacy Policy URL | https://suhohan.kr/baseball-live-kr/privacy |
| Marketing URL | https://suhohan.kr/baseball-live-kr |

- `Korean Baseball Scores & Schedule`(33자)는 부제 30자 한도 초과 → 사용 금지.
- 제3자 콘텐츠 포함 시 사용 권리/허가 필요 (Content Rights 확인).

리뷰 노트(영문):
> Baseball LIVE KR is an unofficial app for Korean baseball live scores, schedules, standings, and game details. It is not affiliated with or endorsed by KBO, its clubs, or any official league organization. The app does not use official league logos or club marks unless separately licensed.

한국어 설명:
> Baseball LIVE KR은 한국 야구 경기 일정, 실시간 스코어, 순위, 경기 상세 정보를 확인할 수 있는 비공식 앱입니다. 특정 리그, 구단, 공식 기관과 제휴하거나 보증받은 앱이 아닙니다.

### Google Play
| 필드 | 값 |
| --- | --- |
| App name (en-US) | Baseball LIVE KR |
| App name (ko-KR) | 한국 야구 라이브 |
| Short description (en-US) | Live Korean baseball scores, schedules, standings, and alerts. *(80자 한도 내)* |
| Short description (ko-KR) | 한국 야구 실시간 스코어, 일정, 순위, 알림을 확인하세요. |
| Full description | 비공식 앱, 실시간 스코어, 일정, 순위, 경기 상세 *(4,000자 한도 내)* |
| Category | Sports |
| Developer website | https://suhohan.kr |
| Privacy policy | https://suhohan.kr/baseball-live-kr/privacy |
| Contact email | support@suhohan.kr |

- 제목/설명/아이콘/대표 이미지가 공식 관계를 오해시키면 안 됨 → KBO, 구단 로고, 공식 엠블럼 배치 금지.
- 신규 출시(2026-07 기준)는 **Android 15 / API level 35 이상** target 필요 (2025-08-31 이후 정책).

---

## 5. 도메인 · HTTPS · API · MCP

| 목적 | URL |
| --- | --- |
| 랜딩 | https://suhohan.kr/baseball-live-kr |
| Privacy | https://suhohan.kr/baseball-live-kr/privacy |
| Terms | https://suhohan.kr/baseball-live-kr/terms |
| Support | https://suhohan.kr/baseball-live-kr/support |
| API Production | https://api.suhohan.kr/baseball-live-kr |
| API Staging | https://staging-api.suhohan.kr/baseball-live-kr |
| MCP | https://mcp.suhohan.kr/baseball-live-kr |
| Status | https://status.suhohan.kr 또는 https://suhohan.kr/status |

API 엔드포인트 (`baseball-live-kr` prefix 래핑):
```
GET https://api.suhohan.kr/baseball-live-kr/v1/health
GET https://api.suhohan.kr/baseball-live-kr/v1/games/today
GET https://api.suhohan.kr/baseball-live-kr/v1/games/{gameId}
GET https://api.suhohan.kr/baseball-live-kr/v1/standings
GET https://api.suhohan.kr/baseball-live-kr/v1/players/search
```

### ATS / HTTPS 하드닝
출시 빌드는 HTTPS 프로덕션 백엔드(`api.suhohan.kr`)를 기본으로 사용하고, ATS arbitrary loads/IP 예외를 포함하지 않는다. 환경변수는 다음 이름을 사용한다.

| 용도 | 값 |
| --- | --- |
| Backend URL override | BASEBALL_LIVE_KR_BASE_URL |
| Staging preset URL | BASEBALL_LIVE_KR_STAGING_BASE_URL |
| Production preset URL | BASEBALL_LIVE_KR_PRODUCTION_BASE_URL |
| Local live fixture flag | KBO_USE_TEST_LIVE_GAME |

> 이 값들은 `Packages/BaseballLiveKRCore/Sources/BaseballLiveKRCore/App/BaseballLiveKREnvironment.swift` 및 `BackendSettingsModel+Resolution.swift` 에 정의되어 iOS 와 공유되므로, rename 은 전 플랫폼 동시 작업으로 처리한다.

### MCP (앱 출시 후 별도 공개)
- 이름 `baseball-live-kr-mcp`, endpoint `https://mcp.suhohan.kr/baseball-live-kr`.
- MVP 는 **읽기 전용**: `get_today_games`, `get_game_detail`, `get_standings`, `search_players`, `get_player_season`.
- 쓰기 작업·계정 연동·개인정보 조회는 MVP 에서 제외.

---

## 6. 권리물 / 로고 / 데이터 정책

MVP 배포는 심사 리스크 최소화를 위해:
1. 공식 리그 로고 사용 금지.
2. 공식 구단 로고/워드마크 사용 금지 (현재 repo 의 `TeamWordmarks`/`TeamBrandAssets` 재검토 필요).
3. 팀 표기는 텍스트명·약칭·자체 색상 토큰으로 제한.
4. 아이콘은 야구공·다이아몬드·스코어보드 등 자체 제작 그래픽 사용.
5. 앱 설명에 "비공식 앱" 명시.
6. 데이터 출처·갱신 주기를 개인정보처리방침 또는 도움말에 명시.

---

## 7. 출시 단계

**Phase 1 — 브랜드 리네이밍**: 외부 노출명에서 `kbo-live` 제거. project.yml Bundle ID → `kr.suhohan.*`, iOS/macOS/Widget 표시명, README·문서 제품명, backend package name, 환경변수 prefix.
**Phase 2 — 도메인/HTTPS**: 랜딩·privacy·terms·support 페이지, `api.suhohan.kr` 공개, ATS 예외 제거, production/staging preset 분리.
**Phase 3 — 권리물 정리**: 공식 로고/워드마크 제거, 자체 컬러/약칭만, 자체 아이콘, 스크린샷 정리, 비공식 문구 추가.
**Phase 4 — TestFlight / Internal Test**: iOS TestFlight, macOS notarization/스토어 경로 결정, Google Play internal, 백엔드 장애 시 stale cache fallback, 경기 상태(우천·더블헤더·연장·종료·postponed) 확인, Widget/Live Activity 갱신 확인.
**Phase 5 — Public Launch**: 웹 랜딩 → GitHub repo rename → iOS TestFlight 외부 → Google Play closed → App Store 심사 → Google Play staged rollout(10%→50%→100%) → MCP·Skill 별도 공개.
