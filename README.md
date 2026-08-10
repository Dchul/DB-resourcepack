# DB-resourcepack

마인크래프트 서버에 배포하는 리소스팩 저장소.

| 파일 | 용도 | 다운로드 주소 |
|---|---|---|
| `DB.zip` | 서버 기본 리소스팩 (GUI 크기 3 기준) | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB.zip |
| `DB_font_scale2.zip` | `/글꼴 2` — GUI 크기 2용 글꼴 덧씌우기 | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB_font_scale2.zip |
| `DB_font_scale4.zip` | `/글꼴 4` — GUI 크기 4용 글꼴 덧씌우기 | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB_font_scale4.zip |

## 갱신 절차

팩을 수정한 뒤:

1. `git add -A && git commit -m "..." && git push`
2. 각 zip의 SHA-1을 다시 계산한다.
3. 서버 설정에 반영한다.
   - `server.properties` → `resource-pack` / `resource-pack-sha1` (기본 팩)
   - `plugins/TagGame/config.yml` → `font-scale.scale-2` / `font-scale.scale-4`의 `url`·`sha1`

다운로드 주소는 파일명이 같으면 변하지 않는다. 내용이 바뀌면 SHA-1만 갱신하면 된다.
