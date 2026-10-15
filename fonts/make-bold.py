# DeltaDotumKR.ttf에서 굵은 판(DeltaDotumKR-Bold.ttf)을 만든다.
#
# 이 글꼴은 도트 글꼴이다(한 점 = 3단위, 한 칸 = 60단위). 마인크래프트 볼드는 글자를 GUI 1픽셀
# 옆에 한 번 더 그리는데, 크기 11에서는 한 점이 0.55픽셀이라 두 벌이 2점 가까이 벌어져 번져 보인다.
# 그래서 글자마다 '오른쪽으로 한 점 옮긴 사본'을 합친 굵은 글자를 따로 만들고, 폭도 한 점 늘린다.
#
#   python -I make-bold.py DeltaDotumKR.ttf DeltaDotumKR-Bold.ttf
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.transformPen import TransformPen
import pathops

DOT = 3

src, dst = sys.argv[1], sys.argv[2]
font = TTFont(src)
glyf, hmtx = font['glyf'], font['hmtx']
gs = TTFont(src).getGlyphSet()   # 원본에서 읽는다 (바꾼 글자를 다시 옮기지 않게)

for name in font.getGlyphOrder():
    adv, lsb = hmtx[name]
    g = glyf[name]
    if g.numberOfContours == 0:
        hmtx[name] = (adv + DOT if adv > 0 else adv, lsb)
        continue
    rec = DecomposingRecordingPen(gs)
    gs[name].draw(rec)
    path = pathops.Path()
    rec.replay(path.getPen())
    shifted = pathops.Path()
    shifted_pen = shifted.getPen()
    rec.replay(TransformPen(shifted_pen, (1, 0, 0, 1, DOT, 0)))
    merged = pathops.op(path, shifted, pathops.PathOp.UNION, fix_winding=True)
    pen = TTGlyphPen(None)
    merged.draw(pen)
    glyf[name] = pen.glyph()
    glyf[name].recalcBounds(glyf)
    hmtx[name] = (adv + DOT, glyf[name].xMin)

for rec in font['name'].names:
    s = rec.toUnicode()
    if rec.nameID in (2, 17):
        rec.string = 'Bold'
    elif rec.nameID in (4, 6):
        rec.string = s.replace('regular', 'Bold').replace('Regular', 'Bold') if 'egular' in s else s + ' Bold'
font['OS/2'].usWeightClass = 700
font['hhea'].advanceWidthMax += DOT
font.save(dst)
print('ok', len(font.getGlyphOrder()))
