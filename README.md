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

## Flake outputs

| 出力 | 用途 |
|---|---|
| `devShells.default` | `nix develop` 用の開発シェル |
| `packages.{default,nix-misskey}` | `nix-misskey` CLI 単体 |
| `apps.default` | `nix run` で CLI を直接呼び出し |
| `formatter` | `nix fmt` で `.nix` を整形 |

例:

```bash
nix run ./.nix-misskey -- status   # dev shell に入らずに CLI 実行
nix build ./.nix-misskey           # CLI バイナリのみビルド
nix fmt                            # .nix ファイルを整形
nix flake check                    # flake 出力を検証
```

## ディレクトリ構成

```
.
├── flake.nix              # flake 入力 / 出力定義
├── shell.nix              # devShell 定義
├── envrc.sample           # direnv 用 .envrc ひな形
├── configs/
│   ├── default.nix
│   ├── misskey/
│   │   ├── default.nix    # dev.yml / test.yml を export
│   │   ├── dev.yml        # 開発用 Misskey 設定
│   │   └── test.yml       # テスト用 Misskey 設定
│   ├── postgres.nix       # postgresql.conf と pg_hba.conf
│   └── redis.nix          # redis.conf
└── scripts/
    ├── default.nix
    ├── misskey-env.nix    # CLI を組み立てる Nix ラッパー
    ├── nix-misskey.sh     # ディスパッチ + top-level cmd_*
    └── lib/               # 機能別モジュール
        ├── common.sh      # ログ・ヘルプ・前提チェック
        ├── postgres.sh    # ensure_postgres / init_postgres など
        ├── redis.sh       # ensure_redis / init_redis など
        ├── config.sh      # ensure_config
        └── tests.sh       # setup_test_env / cmd_test_*
```
