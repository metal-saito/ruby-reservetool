# 03 Scheduler Monitor

予約データの整合性を常駐的にチェックし、自動リトライと計測を行う簡易スケジューラのサンプルです。  
`rufus-scheduler` ライクな `every` DSL を最小構成で実装し、ジョブ失敗時はバックオフしながら再実行します。

## 何が学べるか

- 軽量スケジューラの実装パターン (Tick 方式 / バックオフ)
- 監視ジョブ (IntegrityMonitor) のドメイン分離とテストしやすい設計
- メトリクス、通知、データソースを DI で差し替え可能にしたサンプル

## 使い方

```bash
cd samples/03_scheduler
bundle install
# サンプルデータで 10 tick 実行
bundle exec ruby bin/run_monitor --ticks 10
```

出力例:

```
[Scheduler] IntegrityMonitor started
[Notifier] Invalid timeframe: RES-0003 ...
WARN -- Scheduler: IntegrityMonitor failed, retrying in 5s (attempt 1/3)
...
```

## テスト

```bash
bundle exec rspec
```

Scheduler のリトライ挙動と IntegrityMonitor の検出ロジックをユニットテストで確認しています。

## ファイル構成

- `lib/reservation_tool/scheduler.rb` : `every` DSL を提供するシンプルな scheduler。本体はテスト可能な `tick` ベース。
- `lib/reservation_tool/jobs/integrity_monitor.rb` : 予約データの整合性チェック。重複・期間逆転・終了済み未キャンセルなどを検知。
- `lib/reservation_tool/jobs/json_source.rb` : JSON ファイルを読み込むデータソース。
- `lib/reservation_tool/metrics/collector.rb` : in-memory なメトリクスカウンタ。
- `lib/reservation_tool/notifiers/stdout_notifier.rb` : CLI 実行時に標準出力へ異常を通知。
- `bin/run_monitor` : サンプルデータ (`data/reservations.json`) を監視するエントリポイント。

## 応用

- `json_source.rb` を REST API クライアントに差し替えることで、実際の予約 API の健全性モニタに発展可能
- `StdoutNotifier` を Slack Webhook 実装に置き換えることで、即座にアラート連携が可能
- `metrics/collector.rb` で蓄積した値を Prometheus exporter へ吐き出すことで、Findy 上でもパフォーマンス改善の取り組みを証明しやすくなります


