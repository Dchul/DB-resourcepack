# 공식 서버용 팩(DB_official.zip)을 DB_full.zip에서 만든다.
# 공식 서버에는 치장(HMCCosmetics)·도구 치장·펫(ModelEngine)·칭호가 없으므로 그 자산을 걷어 낸다.
# DB_full.zip이 바뀌면 이 스크립트를 다시 돌린 뒤 README의 갱신 절차를 따른다.
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
    '^assets/minecraft/items/potion\.json$',              # 치장 모양 연결만 들어 있음
    '^assets/minecraft/items/fermented_spider_eye\.json$', # 옷장 창 커서만 들어 있음
    '^assets/minecraft/items/leather_horse_armor\.json$',  # 펫 모양 연결만 들어 있음
    '^assets/minecraft/font/title\.json$',                 # 칭호 그림 글자
    '^assets/taggame/textures/font/title/',
    '^assets/taggame/(items|models/item|textures/item)/(title_|cos_)',
    '^assets/taggame/textures/gui/(cos_|tool_|pet_list|gacha_preview)'
)

# 글꼴 파일 안에서 지울 그림 항목 (위에서 버린 그림을 가리키는 것)
$deadGlyph = 'taggame:(font/title/|gui/(cos_|tool_|pet_list|gacha_preview))'

function Remove-DeadProviders([string]$json) {
    # 그림 항목은 중괄호가 겹치지 않는 평평한 객체라 통째로 들어낼 수 있다
    $json = [regex]::Replace($json, '\s*\{[^{}]*"' + $deadGlyph + '[^"]*"[^{}]*\}\s*,?', '')
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
                $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($text)
                $dst.Write($bytes, 0, $bytes.Length)
            } else {
                $src.CopyTo($dst)
            }
        } finally { $src.Dispose(); $dst.Dispose() }
        $kept++
    }
} finally { $in.Dispose(); $out.Dispose() }

Write-Host "kept $kept, dropped $dropped -> $Output"
