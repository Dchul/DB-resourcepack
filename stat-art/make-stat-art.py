# 공식 서버 통계 창 그림을 stat-art/assets 아래에 만든다 (2026-10-17 소유자가 고른 C안).
#   글꼴 taggame:stat       E000 = 색 점(글자색으로 물듦, 줄 앞에 붙는 갈래 표시)
#   글꼴 taggame:stat_hero  = 갈무리11 굵은 판 크기 16(본문의 2배). 대표 기록 숫자. GUI 3에서 한 점이 4픽셀
#   설명창 테두리 taggame:stat_<갈래> = 어두운 판 + 위쪽에 갈래 색 줄 (아이템의 tooltip_style)
# 결과는 official-pack.ps1이 공식 서버 팩에만 넣는다 (지인 서버 팩에는 안 들어간다).
import io, json, os, shutil
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets')
if os.path.isdir(ROOT):
    shutil.rmtree(ROOT)

def save(rel, data):
    p = os.path.join(ROOT, *rel.split('/'))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if isinstance(data, Image.Image):
        data.save(p, 'PNG')
    else:
        with open(p, 'w', encoding='utf-8', newline='\n') as f:
            f.write(json.dumps(data, ensure_ascii=True))

U = 3  # 글자 한 칸 = 3픽셀 (GUI 3 기준)
dot = Image.new('RGBA', (3 * U, 9 * U), (0, 0, 0, 0))
ImageDraw.Draw(dot).ellipse([0, 9, 8, 17], fill=(255, 255, 255, 255))
save('taggame/textures/font/stat/dot.png', dot)
save('taggame/font/stat.json', {"providers": [
    {"type": "bitmap", "file": "taggame:font/stat/dot.png", "height": 9, "ascent": 8, "chars": [""]}]})
save('taggame/font/stat_hero.json', {"providers": [
    {"type": "ttf", "file": "minecraft:galmuri11_bold.ttf", "size": 16, "oversample": 3}]})

# 설명창 테두리: 3배 해상도(300픽셀 = 100칸). 바닐라와 같은 틀(판은 9칸 안쪽, 테두리 nine_slice 10)
def tooltip(name, accent):
    S, N = 3, 300
    bg = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(bg).rectangle([9 * S, 9 * S, N - 9 * S - 1, N - 9 * S - 1], fill=(18, 20, 25, 246))
    fr = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(fr)
    d.rectangle([9 * S, 9 * S, N - 9 * S - 1, N - 9 * S - 1], outline=(52, 57, 67, 255), width=1)
    if accent:
        d.rectangle([9 * S, 9 * S, N - 9 * S - 1, 9 * S + 1], fill=accent + (255,))
    base = f'taggame/textures/gui/sprites/tooltip/{name}'
    save(base + '_background.png', bg)
    save(base + '_background.png.mcmeta', {"gui": {"scaling": {"type": "nine_slice", "width": 100, "height": 100, "border": 9}}})
    save(base + '_frame.png', fr)
    save(base + '_frame.png.mcmeta', {"gui": {"scaling": {"type": "nine_slice", "width": 100, "height": 100, "border": 10, "stretch_inner": True}}})

# 갈래 색은 플러그인 text/Txt.Stat과 같아야 한다
for name, rgb in [('stat_plain', None), ('stat_combat', 0xFF6B6B), ('stat_guard', 0x4FB3FF), ('stat_apple', 0xFFC94A),
                  ('stat_mine', 0x4FD1A5), ('stat_ench', 0xB78CFF), ('stat_move', 0xFF9F43)]:
    tooltip(name, None if rgb is None else ((rgb >> 16) & 255, (rgb >> 8) & 255, rgb & 255))
print('stat-art ->', ROOT)
