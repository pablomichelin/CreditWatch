# CreditWatch

<div align="center">

![macOS](https://img.shields.io/badge/macOS-Sonoma%2014%2B%20%7C%20Sequoia-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-Proprietary-blue?style=flat-square)
![Release](https://img.shields.io/badge/Release-v0.11.4-green?style=flat-square)

**Monitor em tempo real de cotas, créditos e renovação das principais ferramentas de IA para macOS.**

Desenvolvido por **Pablo Michelin**.

[Download do Aplicativo](https://github.com/pablomichelin/CreditWatch/releases/latest) • [Instalação](#-instalação) • [Provedores](#-provedores-suportados) • [Privacidade](#-privacidade-e-segurança)

</div>

---

## 📌 Visão Geral

O **CreditWatch** é um utilitário nativo de barra de menus para macOS que reúne os saldos, percentuais de uso restantes e datas de renovação das suas ferramentas de IA em uma interface elegante, compacta e atualizada automaticamente.

### 🌟 Destaques
- **Atualização em Segundo Plano:** Atualiza automaticamente a cada 60 segundos, ao abrir o menu e ao acordar o Mac.
- **Leitura Local do Antigravity:** Conexão direta com o serviço local do Antigravity sem necessidade de login web.
- **Interface Minimalista:** Exibe o status consolidado na barra superior e detalhes no painel compacto.
- **100% Privado e Seguro:** Não lê senhas nem cookies externos; sessões isoladas no WebKit nativo da Apple.

---

## 🤖 Provedores Suportados

| Provedor | Métricas Monitoradas | Método de Leitura |
|---|---|---|
| **Cursor** | Cursor Models, Other Models, On-Demand ($) e Data de Renovação | Painel Billing autenticado |
| **OpenAI Codex** | Limite semanal restante, saldo de créditos e data de redefinição | Painel Usage do Codex |
| **ChatGPT** | Detecção do plano (Plus, Pro, Free) e status de cotas | Painel oficial ChatGPT |
| **Claude** | Detecção de plano (Pro, Max, Free) e disponibilidade de limites | Painel Billing / Settings |
| **Google AI Studio** | Quotas RPM (Requests/min), TPM (Tokens/min) e RPD (Requests/day) | Painel Rate Limits |
| **Antigravity** | Gemini semanal/5h e Claude/GPT semanal/5h com datas de reset | RPC local do processo nativo |
| **Grok** | Limites semanais compartilhados dos planos SuperGrok e reset | Painel Settings → Usage |

---

## 🚀 Instalação

### Opção 1: Download Direto (Recomendado)
1. Baixe o pacote mais recente em [Releases](https://github.com/pablomichelin/CreditWatch/releases/latest);
2. Descompacte o arquivo `CreditWatch-v0.11.4-macOS.zip`;
3. Mova o `CreditWatch.app` para a sua pasta **Aplicativos**.

### Opção 2: Compilar a partir do Código-Fonte
Requisitos: macOS Sonoma (14.0+) ou superior e Xcode Command Line Tools.

```bash
git clone https://github.com/pablomichelin/CreditWatch.git
cd CreditWatch
bash Scripts/install.sh
```

---

## 🔒 Privacidade e Segurança

1. **Armazenamento Seguro:** As credenciais de sessão permanecem isoladas no armazenamento seguro padrão do macOS (`WKWebsiteDataStore`).
2. **Sem Coleta de Dados:** O CreditWatch não envia telemetria, estatísticas ou dados de conta para servidores externos.
3. **Credenciais Efêmeras:** Para a integração local do Antigravity, o token CSRF é consultado exclusivamente em memória durante a requisição RPC e nunca é salvo em disco.
4. **Arquivo de Dados Local:** Os números de uso extraídos são salvos apenas em:
   `~/Library/Application Support/CreditWatch/usage.json`

---

## 📂 Documentação e Governança

Para detalhes técnicos e arquitetura do projeto, consulte a pasta [`docs/`](docs/):
- **[`docs/REGRAS.txt`](docs/REGRAS.txt):** Diretrizes de desenvolvimento e governança do código;
- **[`docs/VERSIONAMENTO.txt`](docs/VERSIONAMENTO.txt):** Política de SemVer e checklist de releases;
- **[`docs/ROADMAP.txt`](docs/ROADMAP.txt):** Funcionalidades atuais e futuras integrações;
- **[`docs/CORTEX.txt`](docs/CORTEX.txt):** Guia mestre de contexto para prompts e inteligências artificiais;
- **[`docs/CHANGELOG.txt`](docs/CHANGELOG.txt):** Histórico completo de versões.

---

## 👤 Autor

Criado e mantido por **Pablo Michelin**.  
Contato e suporte: [pablo@systemup.inf.br](mailto:pablo@systemup.inf.br)
