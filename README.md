# nix-misskey

Nix flake で [Misskey](https://github.com/misskey-dev/misskey) の開発環境をセットアップします。

`nix-misskey` という単一の CLI で、PostgreSQL / Redis / Misskey 本体の起動・停止・テストまでを管理します。

## 必要要件

- [Nix](https://nixos.org/download.html)（flakes 有効化済み）
- [direnv](https://direnv.net/)（推奨）

flakes の有効化:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## セットアップ

Misskey 本体を clone し、本リポジトリを `.nix-misskey` として併置します。

```bash
git clone --recursive https://github.com/misskey-dev/misskey.git misskey
cd misskey
git clone https://github.com/hitalin/nix-misskey .nix-misskey
```

direnv を使う場合:

```bash
cp .nix-misskey/envrc.sample .envrc
direnv allow
```

direnv を使わない場合:

```bash
nix develop ./.nix-misskey
```

初回のみ依存関係をインストールしてビルド:

```bash
nix-misskey setup
```

開発サーバーを起動。PostgreSQL / Redis / 設定ファイルが未初期化なら
自動的に立ち上げます。

```bash
nix-misskey start
```

2 回目以降は `nix develop` 後に `nix-misskey start` の 1 コマンドで
完結します。

## コマンド一覧

| コマンド | 説明 |
|---|---|
| `start` | サービスを ensure して dev サーバーを起動（必要なら自動初期化） |
| `setup` | 依存関係をインストールしてビルド + マイグレーション（初回） |
| `stop` | PostgreSQL と Redis を停止 |
| `restart` | `stop` してから `start` |
| `status` | 各サービスの稼働状況を表示 |
| `reset` | `clean` してから `setup`（破壊的に再構築） |
| `clean` | data / node_modules / 設定を削除 |
| `psql` | misskey DB に psql で接続 |
| `redis-cli` | redis-cli を起動 |
| `logs [svc]` | ログを tail (`postgres` / `redis` / `misskey` / `all`) |
| `test` | 全テストを実行 |
| `test:unit` | バックエンドのユニットテストのみ |
| `test:e2e` | バックエンドの E2E テストのみ |
| `help` | ヘルプを表示 |

## ポート

| サービス | ポート |
|---|---|
| Misskey | 3000 |
| Vite (frontend) | 5173 |
| Vite (frontend-embed) | 5174 |
| PostgreSQL | 5433 |
| Redis | 6379 |

## カスタマイズ

設定は `configs/` 配下にあります:

- `misskey/dev.yml` - 開発用 Misskey 設定
- `misskey/test.yml` - テスト用 Misskey 設定
- `postgres.nix` - `postgresql.conf` と `pg_hba.conf`
- `redis.nix` - `redis.conf`

CLI 本体は `scripts/nix-misskey.sh` で、機能別モジュールは
`scripts/lib/{common,postgres,redis,config,tests}.sh` に分離されています。
