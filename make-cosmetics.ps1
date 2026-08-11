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
$key=$null;$nm=$null;$bu=$null;$mo=$null;$gr=$null
function Flush{
  if($script:key -and $script:mo){
    $script:items+=[pscustomobject]@{ key=$script:key; name=$script:nm; part=$script:bu; model=$script:mo; base=$script:gr }
  }
  $script:key=$null;$script:nm=$null;$script:bu=$null;$script:mo=$null;$script:gr=$null
}
foreach($line in ([IO.File]::ReadAllText($src,[Text.Encoding]::UTF8) -split "`r?`n")){
  if($line -match '^\s{2}([A-Za-z0-9_]+):\s*$'){ Flush; $key=$Matches[1] }
  elseif($line -match '^\s+이름:\s*"(.+)"'){ $nm=$Matches[1] }
  elseif($line -match '^\s+부위:\s*(\S+)'){ $bu=$Matches[1] }
  elseif($line -match '^\s+모양:\s*"(.+)"'){ $mo=$Matches[1] }
  elseif($line -match '^\s+그릇:\s*(\S+)'){ $gr=$Matches[1] }
}
Flush

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
  [void]$sb.AppendLine("  item:")
  [void]$sb.AppendLine("    material: $base")
  [void]$sb.AppendLine("    model-id: `"$($i.model)`"")
  [void]$sb.AppendLine("    name: `"<white>$($i.name)`"")
  [void]$sb.AppendLine("    amount: 1")

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
