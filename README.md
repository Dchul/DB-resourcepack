# DB-resourcepack

마인크래프트 서버에 배포하는 리소스팩 저장소.

| 파일 | 용도 | 다운로드 주소 |
|---|---|---|
| `DB.zip` | 서버 기본 리소스팩 (GUI 크기 3 기준) | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB.zip |
| `DB_font_scale2.zip` | `/글꼴 2` — GUI 크기 2용 글꼴 덧씌우기 | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB_font_scale2.zip |
| `DB_font_scale4.zip` | `/글꼴 4` — GUI 크기 4용 글꼴 덧씌우기 | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB_font_scale4.zip |

## 치장(HMCCosmetics)

| 파일 | 하는 일 |
|---|---|
| `cos*` 폴더 | 치장 모양·그림 원본 (받은 날짜별 묶음) |
| `cos-pack.ps1` | 위 폴더들을 `DB.zip` 안에 넣는다 (게임이 알아듣는 연결 파일도 함께 만든다) |
| `cosmetic-items.yml` | 치장의 이름·부위·모양 목록. **여기가 원본이다.** |
| `make-cosmetics.ps1` | 위 목록을 읽어 서버의 HMCCosmetics 설정(치장 정의·창)을 통째로 다시 만든다 |

치장을 늘리거나 이름을 고칠 때: `cosmetic-items.yml` 수정 → `make-cosmetics.ps1` 실행 → (모양이 새로 늘었으면) `cos-pack.ps1` 실행 후 아래 갱신 절차.

## 갱신 절차

팩을 수정한 뒤:

1. `git add -A && git commit -m "..." && git push`
2. 각 zip의 SHA-1을 다시 계산한다.
3. 서버 설정에 반영한다.
   - `server.properties` → `resource-pack` / `resource-pack-sha1` (기본 팩)
   - `plugins/TagGame/config.yml` → `font-scale.scale-2` / `font-scale.scale-4`의 `url`·`sha1`

다운로드 주소는 파일명이 같으면 변하지 않는다. 내용이 바뀌면 SHA-1만 갱신하면 된다.
