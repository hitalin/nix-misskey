# nix-misskey

Nix flake で [Misskey](https://github.com/misskey-dev/misskey) の開発環境をセットアップします。

`nix-misskey` という単一の CLI で、PostgreSQL / Redis / Misskey 本体の起動・停止・テストまでを管理します。

## 必要要件

- [Nix](https://nixos.org/download.html)（flakes 有効化済み）
- [direnv](https://direnv.net/)（推奨）

Node.js は [yamisskey](https://github.com/yamisskey-dev/yamisskey) の
`.node-version` に合わせて `pkgs/nodejs.json` で固定し、公式バイナリを
Nix 内で vendoring します。pnpm は corepack 経由で
`package.json#packageManager` 指定の版を自動取得します。

`.node-version` が変わったら pin を更新します（dev shell 起動時に
ずれを警告します）:

```bash
.nix-misskey/pkgs/update-nodejs.sh "$(cat .node-version)"
```

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

`envrc.sample` は [nix-direnv](https://github.com/nix-community/nix-direnv)
を使い、評価済みの dev shell をキャッシュします（未インストールなら
自動で取得）。2 回目以降のディレクトリ移動は即座に完了します。

direnv を使わない場合:

```bash
nix develop ./.nix-misskey
```

初回のみ依存関係をインストールし、backend をビルドして migrate:

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
| `setup` | 依存インストール + backend build + migrate（初回） |
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
| `test` | 全テスト（frontend / misskey-js / backend unit / backend e2e） |
| `test:unit [vitest args]` | バックエンドのユニットテスト |
| `test:e2e [vitest args]` | バックエンドの E2E テスト |

テストは専用の `misskey-test` データベースと Redis DB 1 を使うため、
開発用データは消えません。検索のテスト用に Meilisearch も
テスト中だけ起動します。例: `nix-misskey test:unit test/unit/misc`

各サブコマンドは `nix-misskey-dev` / `nix-misskey-db-psql` のような
独立した bin として PATH 上にあり、直接呼び出すこともできます。

## ポート

| サービス | ポート |
|---|---|
| Misskey | 3000 |
| Misskey (test) | 61812 |
| Vite (frontend) | 5173 |
| Vite (frontend-embed) | 5174 |
| PostgreSQL | 5433 |
| Redis | 6379 |
| Meilisearch (test 実行中のみ) | 57712 |

## Flake outputs

| 出力 | 用途 |
|---|---|
| `devShells.default` | `nix develop` 用の開発シェル |
| `packages.{default,nix-misskey}` | `nix-misskey` CLI 単体 |
| `packages.nodejs` | `pkgs/nodejs.json` で固定した Node.js |
| `apps.default` | `nix run` で CLI を直接呼び出し |
| `checks` | `nix flake check` で CLI をビルド（全サブコマンドに shellcheck） |
| `formatter` | `nix fmt` で `.nix` を整形 |

例:

```bash
nix run ./.nix-misskey -- status   # dev shell に入らずに CLI 実行
nix build ./.nix-misskey           # CLI バイナリのみビルド
nix fmt                            # .nix ファイルを整形
nix flake check                    # flake 出力を検証
```

