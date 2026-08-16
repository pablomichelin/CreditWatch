const extensionApi = globalThis.browser ?? globalThis.chrome;

extensionApi.action.onClicked.addListener(async (tab) => {
  if (!tab.id) return;
  const [{ result }] = await extensionApi.scripting.executeScript({
    target: { tabId: tab.id },
    func: () => {
      const text = document.body?.innerText || "";
      const pctAfter = (heading, marker = "% used") => {
        const part = text.slice(Math.max(0, text.toLowerCase().indexOf(heading.toLowerCase())));
        const match = part.match(new RegExp("(\\d{1,3})\\s*" + marker.replace("%", "\\%").replace(" ", "\\s*"), "i"));
        return match ? Number(match[1]) : null;
      };
      const params = new URLSearchParams();
      if (location.hostname.includes("cursor.com")) {
        const models = pctAfter("Cursor Models");
        const other = pctAfter("Other Models");
        const ondemandSection = text.slice(Math.max(0, text.toLowerCase().indexOf("on-demand")));
        const amounts = ondemandSection.match(/\$\s*([0-9.]+)\s*\/\s*\$\s*([0-9.]+)/);
        params.set("provider", "cursor");
        if (models !== null) params.set("models", models);
        if (other !== null) params.set("other", other);
        if (amounts && Number(amounts[2])) params.set("onDemand", Math.round(Number(amounts[1]) / Number(amounts[2]) * 100));
        const reset = text.match(/Usage limits reset on[^\n]*\((\d+)\s+days?\s+left\)/i);
        if (reset) params.set("resetDays", reset[1]);
      } else if (location.hostname.includes("chatgpt.com")) {
        const weekly = pctAfter("Limite de uso semanal", "% restante");
        params.set("provider", "codex");
        if (weekly !== null) params.set("weekly", weekly);
        const reset = text.match(/Redefinição\s+([^\n]+)/i);
        if (reset) params.set("resetText", reset[1].trim());
      } else {
        alert("Abra um painel de uso suportado do Cursor ou Codex antes de atualizar.");
        return;
      }
      location.href = "creditwatch://update?" + params.toString();
    }
  });
});
