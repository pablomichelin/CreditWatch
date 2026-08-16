# Conectores de navegador

| Navegador | Pacote |
|---|---|
| Chrome, Edge, Brave, Arc e outros Chromium | `BrowserExtension` |
| Firefox | `BrowserExtension-Firefox` |
| Safari | `BrowserExtension-Safari` (requer Xcode para empacotar) |

Cada conector lê somente a página de uso aberta e envia números resumidos ao
CreditWatch pelo esquema local `creditwatch://`. Não lê senhas, cookies,
conversas ou histórico.

## Instalar

- Chromium: abra a página de extensões, ative modo desenvolvedor e carregue
  `BrowserExtension`.
- Firefox: abra `about:debugging#/runtime/this-firefox`, escolha **Carregar
  extensão temporária** e selecione o `manifest.json` de
  `BrowserExtension-Firefox`.
- Safari: instale Xcode e siga `BrowserExtension-Safari/README.md`.
