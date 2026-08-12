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

`make-cosmetics.ps1`이 만드는 창(`menus/cos_*.yml`)은 지금은 쓰이지 않는다. `/치장` 창은 꼬리잡기 플러그인이 직접 그린다. 치장 정의(`cosmetics/cosmetics.yml`)는 계속 필요하다.

## 도구 치장 (손에 든 도구의 겉모습)

몸에 걸치는 치장과 달리 바깥 플러그인을 쓰지 않는다. 꼬리잡기가 물건에 표시를 직접 붙인다.

| 파일 | 하는 일 |
|---|---|
| `toolskin/` 폴더 | 도구 겉모습의 모양·그림 원본 (낚싯대는 평소 모습과 던진 모습 두 가지) |
| `toolskin-items.yml` | 도구 치장의 이름·종류 목록. **여기가 원본이다.** |
| `toolskin-pack.ps1` | 위 둘을 읽어 `DB.zip`에 넣고, 서버의 `plugins/TagGame/toolskins.yml`까지 다시 만든다 |

이름을 고치거나 치장을 늘릴 때: `toolskin-items.yml` 수정 → `toolskin-pack.ps1` 실행 → 아래 갱신 절차.

움직이는 그림(`.png.mcmeta`)도 함께 들어간다. 이게 빠지면 그림이 세로로 늘어난 채 보인다.

## 창 그림 (GUI)

| 파일 | 하는 일 |
|---|---|
| `gui/generic_54_base.png` | 54칸 상자 창에서 칸 자리와 아래 소지품 칸만 그린 원본 |
| `gui/generic_54_frame.png` | 그 위에 씌우는 테두리·판 (위쪽 26칸이 여백) |
| `gui/cos_home.png` `cos_hat.png` `cos_back.png` `cos_hand.png` | 치장 창 네 화면 |
| `gui/tool_home.png` `tool_axe.png` `tool_hoe.png` `tool_pickaxe.png` `tool_rod.png` `tool_sword.png` | 도구 치장 창 여섯 화면 |
| `gui/gacha_preview.png` | 뽑기 미리보기 창 (위쪽 보라색 띠는 넣을 때 지워진다) |
| `gui-pack.ps1` | 위 두 장을 합쳐 상자 창 바탕을 만들고, 치장 창 네 장과 투명 물건 모양을 `DB.zip`에 넣는다 |

치장 창 그림은 창 제목에 글자 하나로 얹는 방식이라 위치 값(`ascent 39`)과 칸 번호가 서로 맞아야 한다. 그림에서 칸 자리를 옮겼다면 꼬리잡기 플러그인의 치장 창 칸 번호도 함께 봐야 한다.

## 갱신 절차

팩을 수정한 뒤:

1. `git add -A && git commit -m "..." && git push`
2. 각 zip의 SHA-1을 다시 계산한다.
3. 서버 설정에 반영한다.
   - `server.properties` → `resource-pack` / `resource-pack-sha1` (기본 팩)
   - `plugins/TagGame/config.yml` → `font-scale.scale-2` / `font-scale.scale-4`의 `url`·`sha1`

다운로드 주소는 파일명이 같으면 변하지 않는다. 내용이 바뀌면 SHA-1만 갱신하면 된다.
