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
