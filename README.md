# GitHub Open In New Tab

github.com / gist.github.com 上のリンクを左クリックしたとき、新規タブで開く Chrome 拡張 (MV3)。

## インストール

1. `chrome://extensions` を開く
2. 右上の「デベロッパーモード」を ON
3. 「パッケージ化されていない拡張機能を読み込む」でこのディレクトリを選択

## 挙動

- 左クリック (修飾キーなし) のみ差し替える。Ctrl / Shift / 中クリックは Chrome 標準のまま
- 既定は新規タブへフォーカスを移す。裏タブで開いて元タブに留まりたいなら `content.js` の `OPEN_IN_BACKGROUND` を `true` にする
- 新規タブは元タブの隣に開く

## 差し替えないリンク

| 条件 | 理由 |
|---|---|
| `target` 指定あり | ブラウザ標準の挙動に任せる |
| `download` 属性 | タブを開いても意味がない |
| `data-turbo-method` / `data-method` | GET 以外は新規タブで再現できない |
| `role="button"` / `aria-haspopup` | メニュー開閉など遷移が目的でない |
| `http(s)` 以外のスキーム | `javascript:` `mailto:` など |
| ページ内アンカー (`#...`) | 現在のタブでスクロールさせる |

## 対象サイトを増やす

`manifest.json` の `content_scripts[].matches` に追記する (例: GitHub Enterprise のホスト)。

## リリース

1. `make bump` で `manifest.json` の `version` の末尾を 1 上げる
2. `make` で `dist/github-open-in-new-tab-<version>.zip` を作る
3. Chrome Web Store のデベロッパーダッシュボードに zip をアップロードする
4. `manifest.json` をコミットする。別の clone や worktree の `make bump` はコミット済みの `version` から上げる

- バージョンは `manifest.json` の `version` だけで管理する。ストアは前回より大きい `version` しか受け付けないので、アップロードのたびに上げる
- メジャー / マイナーを上げるときは `manifest.json` を手で編集する
- `version` が Chrome の形式 (ドット区切りの整数 1〜4 個、各 0〜65535、先頭ゼロなし、すべて 0 は不可) に合わないと `make` と `make bump` は失敗する
- `dist/` には最後に作った zip だけが残る
- `jq` と `zip` が要る
- `make test` で上の振る舞いを確かめる (`tests/package_test.sh`。使い捨てのコピー上で動く)

### zip に入るファイル

| ファイル | 扱い |
|---|---|
| `manifest.json` `background.js` `content.js` | 必須。無ければ `make` は失敗する |
| `icons/*.png` `README.md` | あれば入れる |
| 上記以外 (`CLAUDE.md` `.git` `.tasks*` `Makefile` など) | 入れない |

同梱するファイルを増やすときは `Makefile` の `FILES` に足す。
