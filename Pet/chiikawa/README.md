# 치이카와 펫

원본: Chiikawa Mod by Dwinovo, https://github.com/Dwinovo/minecraft-chiikawa (그림·모양·움직임은 CC BY-NC-SA 4.0, `LICENSE-ASSETS.txt`). 상업적으로 쓰면 안 된다.

| 자리 | 내용 |
|---|---|
| `source/` | 모드의 모양(Bedrock geo)·움직임·그림 원본 (브랜치 1.21.1) |
| `geo2bb.ts` | 원본을 ModelEngine용 `.bbmodel`로 바꾼다. `deno run -A geo2bb.ts source <캐릭터> <출력.bbmodel> <모양이름>` |
| `icons/` | 모드의 인형 그림(16x16). `/펫`·`/치이카와` 창 칸 그림으로 쓴다 (`taggame:pet_<이름>`) |

변환기가 하는 일: 평소에 숨겨진 표정 부위(입 벌림·웃는 눈·눈물·땀·시험지·가방끈 등)는 뺀다. 아이템 모양이 담을 수 없는 각도로 돌아간 조각은 따로 돌린 부위로 감싼다. 움직임은 idle·walk·blink 셋만 옮긴다. hitbox 부위를 덧붙인다.

서버 배치: `plugins/ModelEngine/blueprints/chiikawa/<이름>.bbmodel`, 단 **쿠리만쥬는 자리(12개 제한)가 모자라 `internals/blueprints/internal_fire.bbmodel`에 모양 이름 `internal_fire`로 들어간다.** MythicMobs 몹은 `Packs/chiikawa`, MCPets 펫은 `Pets/chiikawa`.
