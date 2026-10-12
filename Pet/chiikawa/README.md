# 치이카와 펫

원본: Chiikawa Mod by Dwinovo, https://github.com/Dwinovo/minecraft-chiikawa (그림·모양·움직임은 CC BY-NC-SA 4.0, `LICENSE-ASSETS.txt`). 상업적으로 쓰면 안 된다.

| 자리 | 내용 |
|---|---|
| `source/` | 모드의 모양(Bedrock geo)·움직임·그림 원본 (브랜치 1.21.1) |
| `geo2bb.ts` | 원본을 ModelEngine용 `.bbmodel`로 바꾼다. `deno run -A geo2bb.ts source <캐릭터> <출력.bbmodel> <모양이름>` |
| `icons/` | 모드의 인형 그림(16x16). `/펫`·`/치이카와` 창 칸 그림으로 쓴다 (`taggame:pet_<이름>`) |

변환기가 하는 일: 평소에 숨겨진 표정 부위(눈물·땀·시험지·가방끈 등)는 뺀다. 웃는 눈(happyeyes)과 하치와레·우사기의 벌린 입(mouth3)은 남겨 두고 플러그인이 평소에 숨긴다. 아이템 모양이 담을 수 없는 각도로 돌아간 조각은 따로 돌린 부위로 감싼다. 움직임은 idle·walk·blink·run·sit·swim·swim_stand·happy·clap·crab_greeting·eat·drink를 옮긴다(캐릭터마다 없는 것도 있다). 머리(allhead)는 `h_allhead`로 바꿔 사람 쪽으로 돌게 하고, 오른손 자리(RightHandLocator) 밑에 `ir_hand`를 달아 손에 든 아이템을 그리게 한다. 모드의 HeldItemLayer와 똑같이 손 자리에서 1px 아래·2px 앞, X -72도(눕히기 -90 + 팔 들기 18), 크기 0.6이다. 이 부위엔 조각이 없어서 고쳐도 팩은 바뀌지 않는다(서버 재시작만). hitbox 부위를 덧붙인다. 목소리는 `sounds/`, `pet-icon-pack.ps1`이 팩에 넣는다.

서버 배치: `plugins/ModelEngine/blueprints/chiikawa/<이름>.bbmodel`, 단 **쿠리만쥬는 자리(12개 제한)가 모자라 `internals/blueprints/internal_fire.bbmodel`에 모양 이름 `internal_fire`로 들어간다.** MythicMobs 몹은 `Packs/chiikawa`, MCPets 펫은 `Pets/chiikawa`.
