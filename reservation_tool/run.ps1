#!/usr/bin/env powershell
$ErrorActionPreference = 'Stop'

# 出力エンコーディング（UTF-8）
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$PSDefaultParameterValues['Out-File:Encoding'] = 'UTF8'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# Playwright ブラウザパス（同梱版）
$env:PLAYWRIGHT_BROWSERS_PATH = Join-Path $root 'ms-playwright'

function Show-Header {
  # config.jsonから待機時間を読み取る
  $configPath = Join-Path $root 'config.json'
  $waitTime = "すぐ実行します。"
  
  if (Test-Path $configPath) {
    try {
      $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
      $waitUntilTime = $config.run.wait_until_time
      if ($waitUntilTime) {
        $waitTime = $waitUntilTime
      }
    } catch {
      # エラーが発生してもデフォルト値を使用
    }
  }
  
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
  Write-Host '     🏢  施設予約自動化ツール  🤖'
  Write-Host ''
  Write-Host '        Powered by Playwright + Python'
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
  Write-Host ' 📝 設定ファイル : config.json'
  Write-Host ' 📊 ログ出力先   : logs フォルダ'
  Write-Host " ⏰ 待機時間     : $waitTime"
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
}

function Show-Flow {
  Write-Host '  🚀 ツール起動中...'
  Start-Sleep -Milliseconds 600
  Write-Host ''
  Write-Host '  ------------------------------------------------'
  Write-Host '  【実行フロー】'
  Write-Host '  ------------------------------------------------'
  Write-Host '   ① 🔐 ログイン処理'
  Write-Host '   ② 🏢 施設選択'
  Write-Host '   ③ 📝 フォーム自動入力'
  Write-Host '   ④ 🖱️  予約ボタン押下'
  Write-Host '   ⑤ 💬 結果をポップアップ通知'
  Write-Host '  ------------------------------------------------'
  Write-Host ''
  Write-Host '  ⏳ 処理実行中... しばらくお待ちください'
  Write-Host ''
  Write-Host '  💡 ブラウザが開きます'
  Write-Host '  💡 ポップアップに注目してください！'
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
}

function Show-Error($code) {
  Write-Host '===================================================='
  Write-Host ''
  Write-Host '     ❌ エラーが発生しました'
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
  Write-Host '  📋 トラブルシューティング:'
  Write-Host ''
  Write-Host '   ① logs フォルダの最新ログを確認'
  Write-Host '   ② config.json の設定を確認'
  Write-Host '   ③ インターネット接続を確認'
  Write-Host '   ④ マッキーに質問しよう！'
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
  [void](Read-Host '続行するには Enter を押してください...')
}

function Show-Ok {
  Write-Host '===================================================='
  Write-Host ''
  Write-Host '     ✅ ツールを正常に終了しました！'
  Write-Host ''
  Write-Host '     🎉 お疲れ様でした！'
  Write-Host ''
  Write-Host '===================================================='
  Write-Host ''
}

try {
  Show-Header
  Show-Flow

  $exe = Join-Path $root 'reservation_tool.exe'
  if (-not (Test-Path $exe)) {
    throw "実行ファイルが見つかりません: $exe"
  }

  # EXE を直接起動（シンプルな方法）
  Write-Host ''
  
  # 非同期でEXEを起動
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $exe
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  
  try {
    $proc = [System.Diagnostics.Process]::Start($psi)
    Write-Host "EXEを起動しました (PID: $($proc.Id))" -ForegroundColor Cyan
  } catch {
    Write-Host "EXE起動エラー: $_" -ForegroundColor Red
    Show-Error -code 1
    exit 1
  }
  
  Write-Host ''
  
  # 10秒待機してEXEの状態を確認
  Start-Sleep -Seconds 10
  
  Write-Host ''
  
  # プロセスの状態をチェック
  if ($proc.HasExited) {
    # EXEが既に終了している
    $code = $proc.ExitCode
    
    if ($code -eq 0) {
      Show-Ok
      [void](Read-Host '何かキーを押すと終了します...')
      exit 0
    } else {
      Show-Error -code $code
      exit $code
    }
  } else {
    # EXEがまだ実行中（正常）
    Write-Host '===================================================='
    Write-Host ''
    Write-Host '     ✅ ブラウザが開きました！'
    Write-Host ''
    Write-Host '===================================================='
    Write-Host ''
    Write-Host '  【次の手順】'
    Write-Host '  1. ブラウザで予約内容を確認'
    Write-Host '  2. 「予約を確定する」ボタンを押す'
    Write-Host '  3. 予約完了後、ブラウザを閉じる'
    Write-Host '  4. このコンソールでEnterキーを押す'
    Write-Host ''
    Write-Host '  ⚠️ Enterを押すと、ブラウザとツールが終了します'
    Write-Host '     必ず予約を確定してからEnterを押してください'
    Write-Host ''
    Write-Host '===================================================='
    Write-Host ''
    
    # ユーザーがEnterを押すまで待機
    try {
      [void](Read-Host '予約が完了したら、Enterキーを押してください')
    } catch {
      # ウィンドウが閉じられた場合も処理を続行
    }
    
    # EXEプロセスを全て強制終了
    Write-Host ''
    Write-Host 'ツールを終了しています...' -ForegroundColor Yellow
    
    try {
      # reservation_tool.exe の全プロセスを強制終了
      $allProcs = Get-Process -Name reservation_tool -ErrorAction SilentlyContinue
      $procCount = 0
      
      foreach ($p in $allProcs) {
        try {
          Stop-Process -Id $p.Id -Force
          $procCount++
        } catch {}
      }
      
      Start-Sleep -Milliseconds 500
      
      # 再確認して残っていれば強制終了
      $remaining = Get-Process -Name reservation_tool -ErrorAction SilentlyContinue
      if ($remaining) {
        foreach ($p in $remaining) {
          try { $p.Kill() } catch {}
        }
      }
      
      Write-Host "✓ 終了しました（$procCount 個のプロセスを停止）" -ForegroundColor Green
    } catch {
      Write-Host "終了処理エラー: $_" -ForegroundColor Red
    }
    
    Write-Host ''
    Start-Sleep -Milliseconds 500
    exit 0
  }
}
catch {
  Write-Host ''
  Write-Host '========================================' -ForegroundColor Red
  Write-Host '  エラーが発生しました' -ForegroundColor Red
  Write-Host '========================================' -ForegroundColor Red
  Write-Host ''
  Write-Host "エラー内容: $_"
  Write-Host ''
  Write-Host "エラー詳細:"
  Write-Host "  種類: $($_.Exception.GetType().FullName)"
  Write-Host "  メッセージ: $($_.Exception.Message)"
  Write-Host ''
  Write-Host '【対処方法】'
  Write-Host '1. 「診断.bat」を実行して結果を共有してください'
  Write-Host '2. ウイルス対策ソフトが reservation_tool.exe をブロックしていませんか？'
  Write-Host '3. ms-playwright フォルダが同じフォルダにありますか？'
  Write-Host ''
  [void](Read-Host 'Enterキーを押して終了...')
  exit 1
}


