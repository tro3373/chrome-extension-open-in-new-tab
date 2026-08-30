// github.com 上のリンク左クリックを、新規タブで開くように差し替える。
'use strict';

// true: 裏タブで開いて現在のタブに留まる / false: 新規タブへフォーカスを移す
const OPEN_IN_BACKGROUND = true;

const isPlainLeftClick = (e) =>
  e.button === 0 && !e.ctrlKey && !e.metaKey && !e.shiftKey && !e.altKey;

// composedPath を使い、shadow DOM 内のリンクも拾う
const findAnchor = (e) => {
  for (const node of e.composedPath()) {
    if (node instanceof HTMLAnchorElement && node.href) return node;
  }
  return null;
};

const stripHash = (url) => url.origin + url.pathname + url.search;

const shouldHijack = (a) => {
  // 既に別タブ/別ウィンドウ指定のものはブラウザに任せる
  if (a.target && a.target !== '_self') return false;
  // ダウンロードリンクはタブを開いても意味がない
  if (a.hasAttribute('download')) return false;
  // GET 以外 (Turbo/Rails の delete など) は新規タブでは再現できない
  if (a.hasAttribute('data-turbo-method') || a.hasAttribute('data-method')) return false;
  // メニュー開閉など、遷移が主目的でないリンク
  if (a.getAttribute('role') === 'button') return false;
  if (a.hasAttribute('aria-haspopup')) return false;

  let url;
  try {
    url = new URL(a.href);
  } catch {
    return false;
  }
  // javascript:, mailto:, vscode: などは対象外
  if (url.protocol !== 'https:' && url.protocol !== 'http:') return false;
  // ページ内アンカーは現在のタブで動かす
  if (stripHash(url) === stripHash(new URL(location.href))) return false;

  return true;
};

document.addEventListener(
  'click',
  (e) => {
    if (e.defaultPrevented) return;
    if (!isPlainLeftClick(e)) return;

    const a = findAnchor(e);
    if (!a) return;
    if (!shouldHijack(a)) return;

    const url = a.href;
    e.preventDefault();
    e.stopPropagation();

    // 拡張のリロード等で context が死んでいる場合は通常遷移にフォールバックする
    try {
      chrome.runtime.sendMessage({ type: 'open-in-new-tab', url, background: OPEN_IN_BACKGROUND }, () => {
        if (chrome.runtime.lastError) location.href = url;
      });
    } catch {
      location.href = url;
    }
  },
  true,
);
