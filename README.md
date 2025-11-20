# ReserveTool Ruby Samples

このリポジトリは、架空の予約管理システムを題材にした Ruby 技術サンプル集です。  
1 ディレクトリ 1 トピックの構成にすることで、Findy やポートフォリオでアピールしやすい実装要素を整理しています。

## サンプル一覧

| ディレクトリ | テーマ | 主な技術要素 |
| --- | --- | --- |
| `samples/01_cli_reservation` | CLI での予約登録・一覧表示 | `OptionParser` / YAML 永続化 / 単体テスト (RSpec) |
| `samples/02_http_api` | Rack(Sinatra) ベースの予約 API | DDD 風ドメインオブジェクト / Rack::Test / JSON API |
| `samples/03_scheduler` | 予約データの整合性監視と自動リトライ | `rufus-scheduler` 互換のシンプルスケジューラ / 冪等ロジック / 計測フック |

## 推奨バージョン

- Ruby 3.2 以上
- Bundler 2.5 以上

`.ruby-version` に記載のバージョンを使用すると、各サンプルの Gem バージョンと整合が取れます。

## 使い方

1. ルート直下で `direnv allow` などを行い、Ruby バージョンを合わせます。
2. サンプルごとに `bundle install` を実行します。
3. `README.md` の手順に従ってアプリケーションまたはテストを実行します。

## Findy スコア向上の観点

- ドキュメントで設計判断とテスト範囲を明記し、エンジニアリング判断力を示す
- 各ディレクトリで異なる Ruby エコシステム (CLI / API / バックグラウンド) をカバー
- RSpec や Rack::Test など、実務で使われるライブラリを用いた実装を配置

このレポジトリをベースに、Qiita や Zenn などで解説記事を書くと Findy プロフィールにも好影響です。
