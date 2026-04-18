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

初回のみ:

```bash
nix-misskey setup
```

開発サーバーを起動:

```bash
nix-misskey start
```

## コマンド一覧

| コマンド | 説明 |
|---|---|
| `setup` | PostgreSQL / Redis / 設定ファイル / 依存関係を初期化 |
| `start` | フロントエンド + バックエンドを起動 |
| `stop` | PostgreSQL と Redis を停止 |
| `restart` | `stop` してから `start` |
| `status` | 各サービスの稼働状況を表示 |
| `reset` | `clean` してから `setup` |
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

- `misskey.nix` - Misskey の `default.yml` / `test.yml`
- `postgres.nix` - `postgresql.conf` と `pg_hba.conf`
- `redis.nix` - `redis.conf`

CLI スクリプト本体は `scripts/nix-misskey.sh` です。
