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

Misskey 本体を clone し、そのルートで dev shell に入って `nix-misskey dev`
を実行します。初回は `dev` が依存インストール・backend ビルド・migrate
（`nix-misskey setup` 相当）を自動で行ってから起動します。

この最短手順は、固定している Node.js が checkout の `.node-version` と
一致する場合に使えます（ずれていると dev shell 起動時に警告します）。
ずれている場合は、下の「nix-misskey 自体を変更する場合」の手順で
pin を更新してください。

```bash
git clone https://github.com/misskey-dev/misskey.git && cd misskey
echo 'use flake github:hitalin/nix-misskey' > .envrc && direnv allow
nix-misskey dev
```

direnv を使わない場合は `nix develop github:hitalin/nix-misskey` で
dev shell に入ります。

環境を作り直すときは `nix-misskey clean`（DB と設定を削除）または
`nix-misskey clean-all`（加えて `node_modules` も削除）の後、もう一度
`nix-misskey dev` を実行します。

自動 setup が走るのは、依存が未インストールか DB が未 migrate で、
かつ `.config/default.yml` が nix-misskey の生成したままの場合だけです。
設定を編集している場合や、pull 後に依存・migration が増えた場合は
`nix-misskey setup` / `nix-misskey migrate` を実行してください。

### nix-misskey 自体を変更する場合

本リポジトリを `.nix-misskey` として併置し、ローカルの flake を使います
（Node.js の pin 更新もこちらで行います）。

```bash
git clone https://github.com/hitalin/nix-misskey .nix-misskey
cp .nix-misskey/envrc.sample .envrc
direnv allow
```

`envrc.sample` は [nix-direnv](https://github.com/nix-community/nix-direnv)
を使い、評価済みの dev shell をキャッシュします（未インストールなら
自動で取得）。2 回目以降のディレクトリ移動は即座に完了します。

direnv を使わない場合は `nix develop ./.nix-misskey` です。

以前の `envrc.sample` をコピーした `.envrc` は、なくなったディレクトリを
監視しようとして direnv がエラーを表示し、`modules/` の変更も反映
されません。コピーし直してください。

## コマンド一覧

Misskey 本家の `package.json#scripts` 命名に揃えています
（フラット階層、修飾はコロン区切り）。

**App / lifecycle**

| コマンド | 説明 |
|---|---|
| `dev` | サービスを ensure し、初回は `setup` してから `pnpm dev` |
| `setup` | 依存インストール + backend build + migrate（初回は `dev` が自動実行） |
| `build` | `pnpm build`（production） |
| `migrate` | `pnpm migrate` |
| `revert` | `pnpm revert`（直前のマイグレーションを巻き戻し） |

**Services**

| コマンド | 説明 |
|---|---|
| `status` | PostgreSQL / Redis の稼働状況 |
| `stop` | 全サービスを停止 |
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

## 構成

機能ごとに `modules/<name>/` へ分かれています。各モジュールが必要な
パッケージ・環境変数・設定ファイル・シェルライブラリ・サブコマンドを
宣言し、`cli.nix`（CLI とヘルプ）と `shell.nix`（dev shell）がそれを
組み立てます。PostgreSQL / Redis / Misskey のポートや DB 名は各モジュールの
`default.nix` で一度だけ定義し、設定ファイルと環境変数の両方に使います。

| モジュール | 内容 |
|---|---|
| `core` | ログ出力などの共通ヘルパー |
| `misskey` | Node.js / pnpm、`.config/default.yml`、`dev` `setup` `build` `migrate` `revert` |
| `services` | 各サービスの hook から生成する `status` `stop` `logs` |
| `cleanup` | `clean` `clean-all` `reset` |
| `postgres` | PostgreSQL と `db:*` |
| `redis` | Redis と `cache:*` |
| `meilisearch` | テスト用 Meilisearch |
| `test` | `.config/test.yml` と `test` `test:*` |

## Flake outputs

| 出力 | 用途 |
|---|---|
| `devShells.default` | `nix develop` 用の開発シェル |
| `packages.{default,nix-misskey}` | `nix-misskey` CLI 単体 |
| `packages.nodejs` | `pkgs/nodejs.json` で固定した Node.js |
| `apps.default` | `nix run` で CLI を直接呼び出し |
| `checks` | `nix flake check` で CLI をビルド（全サブコマンドに shellcheck）し、PostgreSQL / Redis を実際に起動する smoke test を実行 |
| `formatter` | `nix fmt` で `.nix` を整形 |

例:

```bash
nix run ./.nix-misskey -- status   # dev shell に入らずに CLI 実行
nix build ./.nix-misskey           # CLI バイナリのみビルド
nix fmt                            # .nix ファイルを整形
nix flake check                    # flake 出力を検証
```

