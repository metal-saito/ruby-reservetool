# 施設予約自動化ツール

Playwright + Python による公共施設予約システムの自動化ツールです。

---

## 📦 使い方（エンドユーザー向け）

### **✅ RELEASE フォルダを使用してください**

このプロジェクトの完成品は **`RELEASE`** フォルダにあります。

```
RELEASE/
├── run.bat                  ← これをダブルクリック！
├── run.ps1                  （run.batから呼ばれます）
├── reservation_tool.exe     （メインプログラム）
├── config.json              ← 設定ファイル（編集してください）
├── ms-playwright/           （ブラウザ同梱）
├── logs/                    （実行ログが保存されます）
├── README.txt               （簡易マニュアル）
├── ユーザーマニュアル.md
└── ユーザーマニュアル.html
```

### 実行手順

1. **`RELEASE/config.json`** を編集して、ログイン情報と予約内容を設定
2. **`RELEASE/run.bat`** をダブルクリック
3. ブラウザが自動で開き、予約処理が実行されます
4. 確認画面に到達したら、内容を確認して手動で「予約確定」ボタンを押してください

詳しくは **`RELEASE/ユーザーマニュアル.html`** をブラウザで開いてご覧ください。

---

## 🛠️ 開発者向け情報

### プロジェクト構成

```
reservation_tool/
├── main.py                  # メインプログラム（Python）
├── config.json              # 設定ファイルのテンプレート
├── requirements.txt         # Python依存パッケージ
├── run.bat                  # ランチャー（ASCII）
├── run.ps1                  # UIランチャー（PowerShell/UTF-8）
├── reservation_tool.spec    # PyInstaller設定
├── README.md                # このファイル
└── RELEASE/                 # 配布用完成品フォルダ
    └── （上記参照）
```

### 開発環境セットアップ

```bash
# 依存パッケージのインストール
pip install -r requirements.txt

# Playwrightブラウザのインストール
playwright install chromium

# 実行（開発モード）
python main.py
```

### EXEのビルド方法

```bash
# PyInstallerでEXEを作成
python -m PyInstaller --onefile --noconsole --name reservation_tool main.py

# 生成されたEXEをRELEASEに配置
Copy-Item dist\reservation_tool.exe RELEASE\

# 不要な中間ファイルを削除
Remove-Item build, dist -Recurse -Force
```

### 注意事項

- **ルートフォルダのファイル**は開発用です。エンドユーザーには **RELEASE フォルダのみ** を配布してください。
- `run.bat` はASCII専用です。絵文字やUTF-8文字は `run.ps1` に記述してください。
- `main.py` を更新したら必ずEXEを再ビルドして `RELEASE/` に配置してください。

---

## 📝 ライセンス

このプロジェクトは個人利用・友人間の共有を目的としています。
