# [gen] 一键构建：web 产物 → flutter release → Inno 安装包
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  Push-Location webapp
  pnpm install
  pnpm build
  Pop-Location
  flutter build windows --release
  # 用户环境为 Inno 7.1（6.7+/7.1 支持 WizardBackColor/Image 自定义背景）：
  # 优先 Inno 7，其次 x86 Inno 6.7，再从 PATH 兜底
  $cand = @(
    'C:\Program Files\Inno Setup 7\ISCC.exe',
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
  )
  $tool = $cand | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $tool) {
    $cmd = Get-Command ISCC -ErrorAction SilentlyContinue
    if ($cmd) { $tool = $cmd.Source }
  }
  if (-not $tool) { throw '未找到 Inno Setup ISCC.exe，请先安装或加入 PATH' }
  & $tool 'installer\examschedulex.iss'
  if ($LASTEXITCODE -ne 0) { throw "ISCC 编译失败，退出码 $LASTEXITCODE" }
  Write-Host "安装包已生成: dist\ExamScheduleX-Setup-*.exe"
} finally { Pop-Location }