# 01 CLI Reservation

OptionParser と YAML 永続化を使って、ターミナル上で予約の登録・一覧表示・キャンセルを行うサンプルです。  
シンプルな CLI でもドメインロジックをオブジェクトに切り分け、RSpec で挙動を担保する構成になっています。

## セットアップ

```bash
cd samples/01_cli_reservation
bundle install
```

## 使い方

```bash
# 登録
bundle exec ruby bin/reserve add \
  --name "Alice" \
  --resource "Room-A" \
  --starts-at "2025-01-02T10:00" \
  --ends-at "2025-01-02T11:00"

# 一覧
bundle exec ruby bin/reserve list

# キャンセル
bundle exec ruby bin/reserve cancel --id RES-0001
```

## 構成

- `bin/reserve` : エントリポイント。CLI 引数を受け取り `ReservationTool::CLI` に処理を委譲します。
- `lib/reservation_tool/cli.rb` : コマンドルーティングと OptionParser によるバリデーションを担当。
- `lib/reservation_tool/reservation.rb` : 予約エンティティ。ドメイン整合性 (重複・期間など) をチェックします。
- `lib/reservation_tool/store.rb` : YAML ファイルを扱う永続化レイヤー。ID 採番やトランザクション的更新を実装。
- `spec` : CLI とストアのユニットテスト。

## 技術的な見どころ

- YAML を通じた軽量なローカル永続化でも、リポジトリパターンを挟んで責務を分離
- CLI でも `--starts-at` など ISO8601 ベースで受け取り、Time オブジェクトに変換して扱う
- RSpec で副作用のある Store をテストしやすいよう、`Tempfile` を利用して I/O を抽象化

## テスト

```bash
bundle exec rspec
```

主要なビジネスルール (重複予約の拒否、キャンセル結果、CLI 出力) を確認しています。


