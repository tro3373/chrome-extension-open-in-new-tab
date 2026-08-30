'use strict';

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg?.type !== 'open-in-new-tab') return;

  chrome.tabs.create(
    {
      url: msg.url,
      active: !msg.background,
      openerTabId: sender.tab?.id,
      // 開いたタブの隣に差し込む
      index: sender.tab ? sender.tab.index + 1 : undefined,
    },
    () => sendResponse({ ok: !chrome.runtime.lastError }),
  );
  return true; // 非同期で sendResponse するため
});
