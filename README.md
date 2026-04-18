# nix-misskey

Nix flake で [Misskey](https://github.com/misskey-dev/misskey) の開発環境をセットアップします。

`nix-misskey` という単一の CLI で、PostgreSQL / Redis / Misskey 本体の起動・停止・テストまでを管理します。

## 必要要件

- [Nix](https://nixos.org/download.html)（flakes 有効化済み）
- [direnv](https://direnv.net/)（推奨）

Node.js / pnpm のバージョンは
[yamisskey の `.node-version` (22.15.0) と `package.json#packageManager`
(`pnpm@10.30.3`)](https://github.com/yamisskey-dev/yamisskey)
に合わせて固定。Node.js は公式バイナリを Nix 内で vendoring し、pnpm は
Node 同梱の corepack 経由で `packageManager` 指定の版を自動取得します。

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
nix-misskey dev
```

2 回目以降は `nix develop` 後に `nix-misskey dev` の 1 コマンドで
完結します。

## コマンド一覧

Misskey 本家の `package.json#scripts` 命名に揃えています
（フラット階層、修飾はコロン区切り）。

**App / lifecycle**

| コマンド | 説明 |
|---|---|
| `dev` | サービスを ensure して `pnpm dev` |
| `setup` | 依存インストール + build + migrate（初回） |
| `build` | `pnpm build`（production） |
| `migrate` | `pnpm migrate` |
| `revert` | `pnpm revert`（直前のマイグレーションを巻き戻し） |

**Services**

| コマンド | 説明 |
|---|---|
| `status` | PostgreSQL / Redis の稼働状況 |
| `stop` | 両サービスを停止 |
| `logs <db\|cache\|app\|all>` | ログを tail |

**Cleanup**

| コマンド | 説明 |
|---|---|
| `clean` | data / `.config` を削除 |
| `clean-all` | `clean` + `node_modules` + `built` |
| `reset` | `clean-all` + `setup` |

**Database (`db:*`)**

| コマンド | 説明 |
|---|---|
| `db:init` | PostgreSQL を破壊的に再初期化 |
| `db:start` / `db:stop` | 起動・停止（idempotent） |
| `db:psql` | misskey DB に psql で接続 |

**Cache (`cache:*`)**

| コマンド | 説明 |
|---|---|
| `cache:init` | Redis を破壊的に再初期化 |
| `cache:start` / `cache:stop` | 起動・停止（idempotent） |
| `cache:cli` | redis-cli を起動 |

**Test**

| コマンド | 説明 |
|---|---|
| `test` | 全テスト |
| `test:unit` | バックエンドのユニットテスト |
| `test:e2e` | バックエンドの E2E テスト |

各サブコマンドは `nix-misskey-dev` / `nix-misskey-db-psql` のような
独立した bin として PATH 上にあり、直接呼び出すこともできます。

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
| `packages.nodejs` | yamisskey が指定する Node.js 22.15.0 |
| `apps.default` | `nix run` で CLI を直接呼び出し |
| `formatter` | `nix fmt` で `.nix` を整形 |

例:

```bash
nix run ./.nix-misskey -- status   # dev shell に入らずに CLI 実行
nix build ./.nix-misskey           # CLI バイナリのみビルド
nix fmt                            # .nix ファイルを整形
nix flake check                    # flake 出力を検証
```

