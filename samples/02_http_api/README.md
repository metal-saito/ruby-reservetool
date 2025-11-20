# 02 HTTP API

Sinatra を用いた軽量な予約 API サービスのサンプルです。  
アプリケーション層とドメイン層を明示的に分け、Rack::Test で API の受け入れテストを書いています。

## セットアップ & 起動

```bash
cd samples/02_http_api
bundle install
bundle exec rackup
```

デフォルトでは `http://localhost:9292` で起動します。

## エンドポイント

| メソッド | パス | 役割 |
| --- | --- | --- |
| `POST /reservations` | 予約作成 |
| `GET /reservations` | 予約一覧 (開始時刻順) |
| `DELETE /reservations/:id` | 予約キャンセル |

### 例

```bash
curl -X POST http://localhost:9292/reservations \
  -H "Content-Type: application/json" \
  -d '{"user_name":"Alice","resource_name":"Room-A","starts_at":"2025-01-02T09:00:00Z","ends_at":"2025-01-02T10:00:00Z"}'
```

## 構成

- `app.rb` : Sinatra::Base を継承したエンドポイント定義
- `lib/reservation_tool/container.rb` : 依存性注入 (メモリリポジトリを提供)
- `lib/reservation_tool/domain/*` : ドメインモデル (予約エンティティとリポジトリ)
- `spec/app_spec.rb` : Rack::Test による API テスト

## 技術的なポイント

- バリデーションエラーとドメインエラーを HTTP ステータスで明確に返却 (422 / 409 / 404)
- ApplicationService (`CreateReservation`) を挟み、Web 層からドメインルールを隔離
- In-memory リポジトリを用いることでテスト容易性とシンプルさを両立

## テスト

```bash
bundle exec rspec
```

POST/GET/DELETE すべてのユースケースに対して 1st-class なテストを提供しています。


