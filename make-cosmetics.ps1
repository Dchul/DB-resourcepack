<#
  cosmetic-items.yml(치장 목록)을 읽어 HMCCosmetics 설정을 통째로 만들어 낸다.
  이름이 늘어나면 목록 파일만 고치고 이 스크립트를 다시 돌리면 된다.
#>
$ErrorActionPreference='Stop'
$srv="C:\Users\dredr\OneDrive\문서\ServerEngine\servers\server_890160838"
$src="C:\Users\dredr\OneDrive\바탕 화면\Claude Code\Resourcepacks\cosmetic-items.yml"
$hmc="$srv\plugins\HMCCosmetics"

$slotMap=@{ '머리'='HELMET'; '상체'='BACKPACK'; '손'='OFFHAND'; '풍선'='BALLOON' }
$menuOf =@{ '머리'='hat'; '상체'='back'; '손'='hand'; '풍선'='balloon' }
$menuTitle=@{ hat='머리'; back='등·어깨'; hand='손'; balloon='풍선' }

# ── 목록 읽기 ────────────────────────────────────────────────
$items=@()
$key=$null;$nm=$null;$bu=$null;$mo=$null;$gr=$null;$dy=$false
function Flush{
  if($script:key -and $script:mo){
    $script:items+=[pscustomobject]@{ key=$script:key; name=$script:nm; part=$script:bu; model=$script:mo; base=$script:gr; dye=$script:dy }
  }
  $script:key=$null;$script:nm=$null;$script:bu=$null;$script:mo=$null;$script:gr=$null;$script:dy=$false
}
foreach($line in ([IO.File]::ReadAllText($src,[Text.Encoding]::UTF8) -split "`r?`n")){
  if($line -match '^\s{2}([A-Za-z0-9_]+):\s*$'){ Flush; $key=$Matches[1] }
  elseif($line -match '^\s+이름:\s*"(.+)"'){ $nm=$Matches[1] }
  elseif($line -match '^\s+부위:\s*(\S+)'){ $bu=$Matches[1] }
  elseif($line -match '^\s+모양:\s*"(.+)"'){ $mo=$Matches[1] }
  elseif($line -match '^\s+그릇:\s*(\S+)'){ $gr=$Matches[1] }
  elseif($line -match '^\s+색변경:\s*(\S+)'){ $dy=($Matches[1] -eq '예') }
}
Flush

# ── 1인칭에서 안 보이게 할 등 치장 표 읽기 ───────────────────
#  cos-firstperson.ps1 이 만들어 두는 표다. 치장이름과 밀어 올릴 칸수가 적혀 있다.
#  표가 없으면 그냥 그 기능 없이 만든다.
$SelfRows=@{}
$fpFile=Join-Path (Split-Path $src -Parent) 'firstperson.txt'
if(Test-Path $fpFile){
  foreach($line in [IO.File]::ReadAllLines($fpFile,[Text.Encoding]::UTF8)){
    if($line -match '^([A-Za-z0-9_]+)\s+(\d+)\s*$'){ $SelfRows[$Matches[1]]=[int]$Matches[2] }
  }
}

New-Item -ItemType Directory -Force -Path "$hmc\cosmetics","$hmc\menus" | Out-Null

# ── 치장 정의 ────────────────────────────────────────────────
$sb=New-Object Text.StringBuilder
[void]$sb.AppendLine('# 이 파일은 자동으로 만들어진다. 직접 고치지 말 것.')
[void]$sb.AppendLine('# 치장을 늘리거나 이름을 바꾸려면 cosmetic-items.yml 을 고치고 다시 만들어 낸다.')
[void]$sb.AppendLine('')
foreach($i in $items){
  $slot=$slotMap[$i.part]; if(-not $slot){ $slot='HELMET' }
  $base=if($i.base){$i.base}else{'LEATHER_HORSE_ARMOR'}
  [void]$sb.AppendLine("$($i.key):")
  [void]$sb.AppendLine("  slot: $slot")
  [void]$sb.AppendLine("  permission: `"hmccosmetics.cosmetic.$($i.key)`"")
  if($i.dye){ [void]$sb.AppendLine("  dyeable: true") }
  [void]$sb.AppendLine("  item:")
  [void]$sb.AppendLine("    material: $base")
  [void]$sb.AppendLine("    model-id: `"$($i.model)`"")
  [void]$sb.AppendLine("    name: `"<white>$($i.name)`"")
  [void]$sb.AppendLine("    amount: 1")
  # 1인칭에서 안 보이게 하는 등 치장 — 걸친 본인에게만 보여 줄 사본을 함께 적어 준다.
  if($slot -eq 'BACKPACK' -and $SelfRows.ContainsKey($i.key)){
    [void]$sb.AppendLine("  height: $($SelfRows[$i.key])")
    [void]$sb.AppendLine("  firstperson-item:")
    [void]$sb.AppendLine("    material: $base")
    [void]$sb.AppendLine("    model-id: `"$($i.model)_fp`"")
    [void]$sb.AppendLine("    name: `"<white>$($i.name)`"")
    [void]$sb.AppendLine("    amount: 1")
  }

  [void]$sb.AppendLine('')
}
[IO.File]::WriteAllText("$hmc\cosmetics\cosmetics.yml",$sb.ToString(),(New-Object Text.UTF8Encoding($false)))

# ── 창(메뉴) ─────────────────────────────────────────────────
$byMenu=@{}
foreach($i in $items){
  $mk=$menuOf[$i.part]; if(-not $mk){ $mk='hat' }
  if(-not $byMenu.ContainsKey($mk)){ $byMenu[$mk]=@() }
  $byMenu[$mk]+=$i
}
$order=@('hat','back','hand','balloon') | Where-Object { $byMenu.ContainsKey($_) }

# 한 쪽에 들어가는 치장 수: 2~8열 x 0~4행
$slotGrid=@()
foreach($r in 0..4){ foreach($c in 2..8){ $slotGrid+=($r*9+$c) } }
$perPage=$slotGrid.Count   # 35

$made=@()
foreach($mk in $order){
  $list=$byMenu[$mk]
  $pages=[Math]::Max(1,[Math]::Ceiling($list.Count/[double]$perPage))
  for($pg=0;$pg -lt $pages;$pg++){
    $name = if($pg -eq 0){"cos_$mk"} else {"cos_${mk}_$($pg+1)"}
    $m=New-Object Text.StringBuilder
    [void]$m.AppendLine('# 자동 생성 파일. 직접 고치지 말 것.')
    $t=$menuTitle[$mk]; if($pages -gt 1){ $t="$t ($($pg+1)/$pages)" }
    [void]$m.AppendLine("title: `"<dark_gray>치장 — $t`"")
    [void]$m.AppendLine("rows: 6")
    [void]$m.AppendLine('items:')
    # 왼쪽 세로줄: 부위 이동 단추
    $btnSlot=0
    foreach($o in $order){
      [void]$m.AppendLine("  tab_$o`:")
      [void]$m.AppendLine("    slots:")
      [void]$m.AppendLine("      - $btnSlot")
      [void]$m.AppendLine("    item:")
      [void]$m.AppendLine("      material: " + $(if($o -eq $mk){'LIME_STAINED_GLASS_PANE'}else{'GRAY_STAINED_GLASS_PANE'}))
      [void]$m.AppendLine("      name: `"<white>$($menuTitle[$o])`"")
      [void]$m.AppendLine("      amount: 1")
      [void]$m.AppendLine("    type: empty")
      if($o -ne $mk){
        [void]$m.AppendLine("    actions:")
        [void]$m.AppendLine("      any:")
        [void]$m.AppendLine("        - `"[MENU] cos_$o`"")
        [void]$m.AppendLine("        - `"[SOUND] minecraft:ui.button.click 1 1`"")
      }
      $btnSlot+=9
    }
    # 벗기 단추
    [void]$m.AppendLine("  take_off:")
    [void]$m.AppendLine("    slots:")
    [void]$m.AppendLine("      - 49")
    [void]$m.AppendLine("    item:")
    [void]$m.AppendLine("      material: BARRIER")
    [void]$m.AppendLine("      name: `"<red>벗기`"")
    [void]$m.AppendLine("      amount: 1")
    [void]$m.AppendLine("    type: empty")
    [void]$m.AppendLine("    actions:")
    [void]$m.AppendLine("      any:")
    [void]$m.AppendLine("        - `"[UNEQUIP] $($slotMap[($menuOf.GetEnumerator()|Where-Object{$_.Value -eq $mk}|Select-Object -First 1).Key])`"")
    [void]$m.AppendLine("        - `"[SOUND] minecraft:ui.button.click 1 1`"")
    # 쪽 넘김 단추
    if($pg -gt 0){
      $prev = if($pg -eq 1){"cos_$mk"} else {"cos_${mk}_$pg"}
      [void]$m.AppendLine("  page_prev:")
      [void]$m.AppendLine("    slots:")
      [void]$m.AppendLine("      - 47")
      [void]$m.AppendLine("    item:")
      [void]$m.AppendLine("      material: ARROW")
      [void]$m.AppendLine("      name: `"<white>이전 쪽`"")
      [void]$m.AppendLine("      amount: 1")
      [void]$m.AppendLine("    type: empty")
      [void]$m.AppendLine("    actions:")
      [void]$m.AppendLine("      any:")
      [void]$m.AppendLine("        - `"[MENU] $prev`"")
      [void]$m.AppendLine("        - `"[SOUND] minecraft:ui.button.click 1 1`"")
    }
    if($pg -lt $pages-1){
      [void]$m.AppendLine("  page_next:")
      [void]$m.AppendLine("    slots:")
      [void]$m.AppendLine("      - 51")
      [void]$m.AppendLine("    item:")
      [void]$m.AppendLine("      material: ARROW")
      [void]$m.AppendLine("      name: `"<white>다음 쪽`"")
      [void]$m.AppendLine("      amount: 1")
      [void]$m.AppendLine("    type: empty")
      [void]$m.AppendLine("    actions:")
      [void]$m.AppendLine("      any:")
      [void]$m.AppendLine("        - `"[MENU] cos_${mk}_$($pg+2)`"")
      [void]$m.AppendLine("        - `"[SOUND] minecraft:ui.button.click 1 1`"")
    }
    # 치장 칸
    $slice=$list | Select-Object -Skip ($pg*$perPage) -First $perPage
    $idx=0
    foreach($i in $slice){
      [void]$m.AppendLine("  $($i.key):")
      [void]$m.AppendLine("    slots:")
      [void]$m.AppendLine("      - $($slotGrid[$idx])")
      [void]$m.AppendLine("    item:")
      [void]$m.AppendLine("      material: $(if($i.base){$i.base}else{'LEATHER_HORSE_ARMOR'})")
      [void]$m.AppendLine("      model-id: `"$($i.model)`"")
      [void]$m.AppendLine("      name: `"<white>$($i.name)`"")
      [void]$m.AppendLine("      amount: 1")
      [void]$m.AppendLine("      lore:")
      [void]$m.AppendLine("        - `"`"")
      [void]$m.AppendLine("        - `"<gray>가진 것: <white>%HMCCosmetics_unlocked_$($i.key)%`"")
      [void]$m.AppendLine("    type: cosmetic")
      [void]$m.AppendLine("    cosmetic: $($i.key)")
      $idx++
    }
    [IO.File]::WriteAllText("$hmc\menus\$name.yml",$m.ToString(),(New-Object Text.UTF8Encoding($false)))
    $made+=$name
  }
}

Write-Host ("치장 {0}개, 창 {1}개 만듦: {2}" -f $items.Count,$made.Count,($made -join ', '))

# ── 치장 아래 끝 높이 표 ─────────────────────────────────────
#  치장 뽑기 기계 위에서 돌아가는 치장이 상자에 파묻히지 않게 하려면
#  "그 치장의 모양이 어디서부터 시작하는지"를 꼬리잡기 쪽이 알아야 한다.
#  모양 파일에서 가장 아래 지점을 재어 표로 적어 둔다 (한 칸 = 16).
$rootDir=Split-Path $src -Parent

function Model-Bottom([string]$path){
  $j = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
  $min = $null
  foreach($e in $j.elements){
    $x1=[double]$e.from[0]; $y1=[double]$e.from[1]; $z1=[double]$e.from[2]
    $x2=[double]$e.to[0];   $y2=[double]$e.to[1];   $z2=[double]$e.to[2]
    $ys=@()
    if($e.rotation -and $e.rotation.angle -and [double]$e.rotation.angle -ne 0){
      # 기울어진 조각은 여덟 모서리를 실제로 돌려 보고 가장 낮은 점을 찾는다
      $a=[double]$e.rotation.angle * [Math]::PI / 180.0
      $ax=[string]$e.rotation.axis
      $ox=[double]$e.rotation.origin[0]; $oy=[double]$e.rotation.origin[1]; $oz=[double]$e.rotation.origin[2]
      $c=[Math]::Cos($a); $s=[Math]::Sin($a)
      foreach($px in @($x1,$x2)){ foreach($py in @($y1,$y2)){ foreach($pz in @($z1,$z2)){
        $dx=$px-$ox; $dy=$py-$oy; $dz=$pz-$oz
        if($ax -eq 'x'){ $ys += $oy + ($dy*$c - $dz*$s) }
        elseif($ax -eq 'z'){ $ys += $oy + ($dx*$s + $dy*$c) }
        else { $ys += $py }
      }}}
    } else {
      $ys=@($y1,$y2)
    }
    foreach($v in $ys){ if($null -eq $min -or $v -lt $min){ $min=$v } }
  }
  if($null -eq $min){ return 0.0 }
  return [Math]::Round($min,3)
}

$bs=New-Object Text.StringBuilder
[void]$bs.AppendLine('# 이 파일은 자동으로 만들어진다. 직접 고치지 말 것.')
[void]$bs.AppendLine('# 치장마다 모양의 아래 끝이 어디인지 적어 둔 표 (한 칸 = 16).')
[void]$bs.AppendLine('# 치장 뽑기 기계 위에서 돌아가는 높이를 맞추는 데 쓴다.')
[void]$bs.AppendLine('bottoms:')
$bn=0
foreach($i in $items){
  $p=$i.model -split ':'
  $mf="$rootDir\$($p[0])\models\$($p[1]).json"
  if(-not (Test-Path $mf)){ continue }
  [void]$bs.AppendLine("  $($i.key): $(Model-Bottom $mf)")
  $bn++
}
New-Item -ItemType Directory -Force -Path "$srv\plugins\TagGame" | Out-Null
[IO.File]::WriteAllText("$srv\plugins\TagGame\cosmetic-bounds.yml",$bs.ToString(),(New-Object Text.UTF8Encoding($false)))
Write-Host ("치장 높이 표 {0}개 만듦" -f $bn)
