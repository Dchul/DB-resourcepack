# 공식 서버용 팩(DB_official.zip)을 DB_full.zip에서 만든다.
# 공식 서버에는 치장(HMCCosmetics)·도구 치장·펫(ModelEngine)·칭호가 없으므로 그 자산을 걷어 낸다.
# DB_full.zip이 바뀌면 이 스크립트를 다시 돌린 뒤 README의 갱신 절차를 따른다.
#
# 공식 서버 글꼴은 갈무리11(fonts/Galmuri11.ttf, 2026-10-17 소유자 지정, 크기 8)이다. 한 칸 12점 도트 글꼴이라
# 크기 8이면 GUI 크기 3에서 한 점이 화면 2픽셀로 딱 맞는다. Paperlogy 파일과 ttf 항목을 지운 뒤, 본문·볼드·부제·타이틀
# 여섯 벌의 기본 글꼴 참조 바로 앞에 갈무리11 항목을 넣는다. 볼드 세 벌(bold·mid_bold·big_bold)은 제작자가 만든
# 굵은 판 fonts/Galmuri11-Bold.ttf를 쓴다. 마인크래프트 볼드(겹쳐 그리기)는 도트 글꼴에서 번져 보여서 플러그인이
# 볼드를 끄고 이 글꼴로 바꿔 보낸다. 글꼴을 바꾸면 플러그인의 글자 폭 표(Msg.pixelWidth)도 다시 잰다.
# 해상도 배수는 GUI 크기 3 기준: 본문 3, 부제(2배 확대) 6, 타이틀(4배 확대) 12.
#
# 셰이더(modelengine_* 겹침 폴더와 루트 셰이더)는 남긴다. 루트 셰이더는 옛 버전용이라
# 겹침 폴더만 지우면 최신 손님에게 옛 셰이더가 적용돼 팩이 깨질 수 있다.

param(
    [string]$Source = "$PSScriptRoot\DB_full.zip",
    [string]$Output = "$PSScriptRoot\DB_official.zip"
)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 통째로 버리는 파일
$drop = @(
    '^assets/cos\d+/',                       # 치장 모양 묶음
    '^assets/z_cosmetics/',                  # HMCCosmetics 옷장 창
    '^assets/toolskin/',                     # 도구 치장
    '^assets/modelengine/',                  # 펫 모양
    '^assets/taggame/sounds',                # 치이카와 펫 목소리 (sounds.json 포함)
    '^assets/minecraft/items/potion\.json$',              # 치장 모양 연결만 들어 있음
    '^assets/minecraft/items/fermented_spider_eye\.json$', # 옷장 창 커서만 들어 있음
    '^assets/minecraft/items/leather_horse_armor\.json$',  # 펫 모양 연결만 들어 있음
    '^assets/minecraft/font/title\.json$',                 # 칭호 그림 글자
    '^assets/taggame/textures/font/title/',
    '^assets/taggame/(items|models/item|textures/item)/(title_|cos_|pet_)',  # 칭호·치장·치이카와 펫 칸 그림
    '^assets/taggame/textures/gui/(cos_|tool_|pet_list|gacha_preview)',
    '^assets/minecraft/font/paperlogy[^/]*\.ttf$'           # Paperlogy 글꼴
)

$FontSize = 8
$FontFile = "$PSScriptRoot\fonts\Galmuri11.ttf"
$BoldFile = "$PSScriptRoot\fonts\Galmuri11-Bold.ttf"
$FontJsons = @{
    'assets/minecraft/font/default.json' = 3; 'assets/taggame/font/bold.json'     = 3
    'assets/taggame/font/mid.json'       = 6; 'assets/taggame/font/mid_bold.json' = 6
    'assets/taggame/font/big.json'       = 12; 'assets/taggame/font/big_bold.json' = 12
}

function Add-Delta([string]$json, [int]$oversample, [string]$file) {
    $prov = '{"type":"ttf","file":"minecraft:' + $file + '","size":' + $FontSize + ',"oversample":' + $oversample + '},'
    $rx = [regex]'\{\s*"type"\s*:\s*"reference"\s*,\s*"id"\s*:\s*"minecraft:include/space"\s*\}'
    if (-not $rx.IsMatch($json)) { throw "기본 글꼴 참조가 없음" }
    return $rx.Replace($json, { param($m) $prov + $m.Value }, 1)
}

# 글꼴 파일 안에서 지울 그림 항목 (위에서 버린 그림을 가리키는 것)
$deadGlyph = 'taggame:(font/title/|gui/(cos_|tool_|pet_list|gacha_preview))'

function Remove-DeadProviders([string]$json) {
    # 그림 항목은 중괄호가 겹치지 않는 평평한 객체라 통째로 들어낼 수 있다
    $json = [regex]::Replace($json, '\s*\{[^{}]*"' + $deadGlyph + '[^"]*"[^{}]*\}\s*,?', '')
    # Paperlogy 글꼴 항목 (역시 평평한 객체)
    $json = [regex]::Replace($json, '\s*\{[^{}]*"type"\s*:\s*"ttf"[^{}]*\}\s*,?', '')
    # 마지막 항목을 지웠을 때 남는 쉼표 정리
    return [regex]::Replace($json, ',(\s*)\]', '$1]')
}

if (Test-Path $Output) { Remove-Item $Output }
$in = [IO.Compression.ZipFile]::OpenRead($Source)
$out = [IO.Compression.ZipFile]::Open($Output, 'Create')
$kept = 0; $dropped = 0
try {
    foreach ($e in $in.Entries) {
        $name = $e.FullName
        if ($drop | Where-Object { $name -match $_ }) { $dropped++; continue }
        $ne = $out.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
        $src = $e.Open(); $dst = $ne.Open()
        try {
            if ($name -match '^assets/[^/]+/font/[^/]+\.json$') {
                $reader = New-Object IO.StreamReader($src, [Text.Encoding]::UTF8)
                $text = Remove-DeadProviders $reader.ReadToEnd()
                if ($FontJsons.ContainsKey($name)) { $file = if ($name -match 'bold') { 'galmuri11_bold.ttf' } else { 'galmuri11.ttf' }
                    $text = Add-Delta $text $FontJsons[$name] $file }
                $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($text)
                $dst.Write($bytes, 0, $bytes.Length)
            } else {
                $src.CopyTo($dst)
            }
        } finally { $src.Dispose(); $dst.Dispose() }
        $kept++
    }
    $fe = $out.CreateEntry('assets/minecraft/font/galmuri11.ttf', [IO.Compression.CompressionLevel]::Optimal)
    $fs = $fe.Open(); $fb = [IO.File]::ReadAllBytes($FontFile); $fs.Write($fb, 0, $fb.Length); $fs.Dispose()
    $fe = $out.CreateEntry('assets/minecraft/font/galmuri11_bold.ttf', [IO.Compression.CompressionLevel]::Optimal)
    $fs = $fe.Open(); $fb = [IO.File]::ReadAllBytes($BoldFile); $fs.Write($fb, 0, $fb.Length); $fs.Dispose()
} finally { $in.Dispose(); $out.Dispose() }

Write-Host "kept $kept, dropped $dropped -> $Output"
