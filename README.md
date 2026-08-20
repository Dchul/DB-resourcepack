# DB-resourcepack

마인크래프트 서버에 배포하는 리소스팩 저장소.

| 파일 | 용도 | 다운로드 주소 |
|---|---|---|
| `DB_full.zip` | **접속자에게 실제로 내려가는 팩.** `DB.zip` + ItemsAdder 자산 | https://github.com/Dchul/DB-resourcepack/releases/download/pack/DB_full.zip |
| `DB.zip` | 위의 재료. 아래 스크립트들이 만드는 팩 (GUI 크기 3 기준) | (배포되지 않음) |
| `DB_font_scale2.zip` | `/글꼴 2` — GUI 크기 2용 글꼴 덧씌우기 | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB_font_scale2.zip |
| `DB_font_scale4.zip` | `/글꼴 4` — GUI 크기 4용 글꼴 덧씌우기 | https://raw.githubusercontent.com/Dchul/DB-resourcepack/main/DB_font_scale4.zip |

## 글꼴

| 파일 | 하는 일 |
|---|---|
| `font-pack.ps1` | 글꼴 설정 파일을 만들어 `DB.zip`과 GUI 크기별 덧씌우기 팩 두 개에 넣는다 (팩 두 개는 통째로 새로 만든다) |

같은 글꼴을 세 벌씩 굽는다. 마인크래프트가 화면 가운데 큰 글씨를 확대해 그리기 때문이다.

| 이름 | 쓰이는 곳 | 해상도 |
|---|---|---|
| `minecraft:default` / `taggame:bold` | 본문·채팅·창 글씨 | 1배 |
| `taggame:mid` / `taggame:mid_bold` | 화면 가운데 부제 | 2배 |
| `taggame:big` / `taggame:big_bold` | 화면 가운데 타이틀 | 4배 |

꼬리잡기 플러그인이 타이틀·부제 글에 `mid`·`big`을 지정해 내보낸다. 글꼴 이름은 세 팩이
모두 같고 안에 든 해상도만 다르므로, 사람마다 다른 팩을 써도 플러그인은 신경 쓸 게 없다.

## 치장(HMCCosmetics)

| 파일 | 하는 일 |
|---|---|
| `RR.zip` | 치장·도구 모양 원본 보관함. 날짜별 묶음(`assets/cos260523` 등)이 그대로 들어 있다 |
| `cos-manifest.txt` | 각 묶음에서 실제로 쓰는 파일 목록. `RR.zip`에는 골라내고 버린 것까지 있어서 이 목록으로 걸러 낸다 |
| `cos*` 폴더 | 새로 받은 묶음을 따로 두는 자리. `RR.zip`에 이미 들어 있는 묶음은 폴더로 두지 않는다 |
| `cos-pack.ps1` | 위 폴더들과 `RR.zip` 안의 묶음을 `DB.zip`에 넣는다 (게임이 알아듣는 연결 파일도 함께 만든다) |

`cos-pack.ps1`은 폴더로 남아 있는 묶음을 먼저 쓰고, 폴더가 없는 묶음만 `RR.zip`에서 꺼내 쓴다.
꺼낼 때는 `cos-manifest.txt`에 적힌 파일만 가져온다. 묶음의 파일 구성을 바꿨다면 이 목록도 함께 고쳐야 한다.
| `cosmetic-items.yml` | 치장의 이름·부위·모양 목록. **여기가 원본이다.** 색을 바꿀 수 있는 치장에는 `색변경: 예` 를 적는다 |
| `make-cosmetics.ps1` | 위 목록을 읽어 서버의 HMCCosmetics 설정(치장 정의·창)을 통째로 다시 만든다 |

치장을 늘리거나 이름을 고칠 때: `cosmetic-items.yml` 수정 → `make-cosmetics.ps1` 실행 → (모양이 새로 늘었으면) `cos-pack.ps1` 실행 후 아래 갱신 절차.

`make-cosmetics.ps1`이 만드는 창(`menus/cos_*.yml`)은 지금은 쓰이지 않는다. `/치장` 창은 꼬리잡기 플러그인이 직접 그린다. 치장 정의(`cosmetics/cosmetics.yml`)는 계속 필요하다.

## 도구 치장 (손에 든 도구의 겉모습)

몸에 걸치는 치장과 달리 바깥 플러그인을 쓰지 않는다. 꼬리잡기가 물건에 표시를 직접 붙인다.

| 파일 | 하는 일 |
|---|---|
| `toolskin/` 폴더 | 도구 겉모습의 모양·그림 원본 (낚싯대는 평소 모습과 던진 모습 두 가지) |
| `toolskin-items.yml` | 도구 치장의 이름·종류 목록. **여기가 원본이다.** 종류는 곡괭이·도끼·괭이·낚싯대·검·활 |
| `toolskin-pack.ps1` | 위 둘을 읽어 `DB.zip`에 넣고, 서버의 `plugins/TagGame/toolskins.yml`까지 다시 만든다 |

이름을 고치거나 치장을 늘릴 때: `toolskin-items.yml` 수정 → `toolskin-pack.ps1` 실행 → 아래 갱신 절차.

움직이는 그림(`.png.mcmeta`)도 함께 들어간다. 이게 빠지면 그림이 세로로 늘어난 채 보인다.

활은 시위를 당기는 동안 모양이 세 단계로 바뀌므로 `당김모양` 에 세 모양을 빈칸으로 나눠 적는다.

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

## 커스텀 펫 모양 (ModelEngine)

| 파일 | 하는 일 |
|---|---|
| `me-pack.ps1` | ModelEngine이 구워 둔 모양 묶음을 통째로 `DB.zip`에 넣는다 (판별 덧씌우기 목록까지 함께) |
| `RR2.zip` | 몬스터 모양 보관함. 지금 쓰는 곳은 없다 |

커스텀 펫은 두 쪽이 짝을 이룬다. 서버 쪽 원본(`plugins/ModelEngine/blueprints`의 `.bbmodel`)과,
그것으로 ModelEngine이 구워 내는 손님 쪽 그림 묶음이다. 후자가 `DB.zip`에 들어가야 펫이 보인다.

순서를 지켜야 한다.

1. 새 펫 원본을 서버의 `plugins/ModelEngine/blueprints`에 넣는다
2. 서버를 한 번 켰다 끈다 — 이때 그림 묶음이 새로 구워진다
3. `me-pack.ps1`을 돌린다
4. 아래 갱신 절차를 따른다

`.data/cache.json`은 지우지 않는다. 모양마다 붙는 번호를 기억해 두는 파일이라,
지우면 번호가 다시 매겨져서 이미 올려 둔 `DB.zip`과 어긋난다.

## 갱신 절차

팩을 수정한 뒤:

1. `git add -A && git commit -m "..." && git push`
2. 각 zip의 SHA-1을 다시 계산한다.
3. 서버 설정에 반영한다.
   - `server.properties` → `resource-pack` / `resource-pack-sha1` (기본 팩)
   - `plugins/TagGame/config.yml` → `font-scale.scale-2` / `font-scale.scale-4`의 `url`·`sha1`

다운로드 주소는 파일명이 같으면 변하지 않는다. 내용이 바뀌면 SHA-1만 갱신하면 된다.

## ItemsAdder 합치기

ItemsAdder는 자기 자산과 다른 팩을 합쳐 하나의 팩을 만든다. 그래서 배포되는 팩은
`DB.zip`이 아니라 그 결과물을 다듬은 `DB_full.zip`이다.

| 자리 | 내용 |
|---|---|
| 서버 `plugins/DBPack/resourcepack/` | `DB.zip`을 풀어 둔 것. ItemsAdder가 여기를 읽어 합친다 |
| 서버 `plugins/ItemsAdder/output/generated.zip` | ItemsAdder가 만든 합본 |
| `ia-merge.ps1` | 위 합본을 다듬어 `DB_full.zip`으로 만든다 |

ItemsAdder 설정에서 꺼 둔 것들 (요청하지 않은 인게임 변화를 막기 위함):

- 자체 팩 배포(`no-host`) — 팩은 지금까지대로 `server.properties`가 내려보낸다
- 음표블록·버섯블록·후렴화 겉모습 가로채기
- 가죽 갑옷 그림 덮어쓰기와 갑옷 셰이더
- 바닐라 번역 덮어쓰기 (`염색됨` 표시 지우기 등) — `ia-merge.ps1`이 한 번 더 걷어낸다
- 팩 압축·잠금 (직접 만든 자산이 망가지지 않게)

`ia-merge.ps1`이 손보는 것:

1. 글꼴 — ItemsAdder 내부 글꼴은 U+E000~E01A를 쓴다. 마인크래프트는 **앞에 온 항목이 이기고**
   ItemsAdder 항목이 앞에 붙으므로, 같은 글자를 쓰면 DB 쪽 그림이 아예 보이지 않는다.
   그래서 칭호 그림 글자는 U+E900~E908로 옮겨 두었다 (겹치지 않는 자리).
   그래도 ItemsAdder가 버리는 항목이 생길 수 있어, `DB.zip`의 글꼴 항목을 뒤에 다시 붙여 되살린다
2. 바닐라 번역 덮어쓰기 제거
3. 팩 이름을 `DB SERVER`로 되돌림

### 팩을 새로 만들 때

1. 기존대로 `*-pack.ps1`을 돌려 `DB.zip`을 만든다
2. `DB.zip`을 서버 `plugins/DBPack/resourcepack/`에 풀어 덮어쓴다
3. 서버 `plugins/ItemsAdder/output/generated.zip`을 지우고 서버를 재시작한다 (ItemsAdder가 다시 만든다)
4. `ia-merge.ps1 -Generated <합본> -Source <풀어둔 폴더> -Output DB_full.zip`
5. 커밋·푸시 → `gh release upload pack DB_full.zip --clobber` → SHA-1을 `server.properties`에 반영
