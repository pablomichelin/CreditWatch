<div align="center">

# ⚡️ CreditWatch

### Monitor de Créditos e Limites de Ferramentas de IA para macOS

[![macOS](https://img.shields.io/badge/macOS-Sonoma%2014%2B%20%7C%20Sequoia-black?style=for-the-badge&logo=apple&logoColor=white)](#)
[![Release](https://img.shields.io/badge/Vers%C3%A3o-v0.21.62-2ea44f?style=for-the-badge&logo=github)](https://github.com/pablomichelin/CreditWatch/releases/latest)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Apoiar-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/pablomichelin)
[![Privacidade](https://img.shields.io/badge/Privacidade-100%25%20Local-blue?style=for-the-badge&logo=lock)](#)

**Acompanhe limites, créditos, saldos e resets das suas ferramentas de IA em um único app nativo para macOS.**

> **Distribuição pública:** cada nova versão do app é publicada em [GitHub Releases](https://github.com/pablomichelin/CreditWatch/releases/latest) com ZIP ad-hoc para download. macOS pode pedir confirmação na primeira abertura (assinatura local, não notarizada). Quando a distribuição assinada/notarizada estiver habilitada, as releases incluirão DMG/ZIP oficiais.

### 📱 Interface

<p align="center">
  <img src="https://raw.githubusercontent.com/pablomichelin/CreditWatch/main/assets/menubar-preview.jpg" alt="Menu Bar do CreditWatch" width="48%" />
  &nbsp;
  <img src="https://raw.githubusercontent.com/pablomichelin/CreditWatch/main/assets/settings-preview.jpg" alt="Configurações do CreditWatch" width="48%" />
</p>

</div>

---

## 🌟 O que o CreditWatch faz

- **Visão consolidada:** reúne em um único lugar limites, créditos, saldos e horários de renovação das IAs conectadas.
- **Atualização automática:** acompanha as fontes conectadas e permite atualização manual imediata.
- **Burn Rate e capacidade:** usa histórico local para estimar ritmo de consumo e risco de esgotamento quando há dados suficientes.
- **Alertas nativos:** avisa sobre cotas percentuais baixas, esgotamento e renovação sem confundir créditos, moedas ou horas com porcentagem.
- **Privacidade local:** não usa backend intermediário e não lê cookies de outros navegadores.
- **macOS nativo:** Swift, SwiftUI, AppKit e WebKit.

---

## 🤖 Ferramentas acompanhadas

| Ferramenta | Informações acompanhadas |
| :--- | :--- |
| **Cursor** | uso incluído ou pools First-party / Third-party quando expostos; On-Demand monetário explícito |
| **OpenAI Codex** | limite semanal quando explicitamente exposto e saldo de créditos |
| **ChatGPT** | identificação/status do plano e sessão, sem inventar percentual único de uso |
| **Claude** | sessão de 5 horas e limites semanais disponíveis em Usage |
| **Google AI Studio** | RPM, TPM e RPD realmente expostos pelo projeto/modelo |
| **Antigravity** | quotas locais via RPC, incluindo janelas semanais e de 5 horas disponíveis |
| **Grok** | pool semanal pago e Extra Usage Credits quando expostos |
| **Perplexity** | créditos do Computer por bucket ou saldo total explícito |
| **DeepSeek** | saldo preservando a moeda real, USD ou CNY |
| **OpenRouter** | créditos adquiridos, uso total e saldo disponível |
| **v0** | créditos restantes e limite quando expostos |
| **Midjourney** | Fast Time mensal e horas extras separadas quando expostas |

---

## 📦 Versões

As mudanças públicas são registradas em **GitHub Releases**. Cada bump de versão do app gera release pública com ZIP ad-hoc para download.

Enquanto a notarização Apple Developer não estiver habilitada, o ZIP é assinado ad-hoc localmente. macOS pode solicitar abertura manual na primeira execução.

---

## 🔒 Privacidade e segurança

- dados de uso e histórico ficam no Mac;
- sessões web usam o WebKit controlado pelo próprio app;
- sem backend intermediário do CreditWatch;
- sem persistência de senhas ou tokens efêmeros pelo app.

---

## ☕ Apoie o projeto

Se o CreditWatch é útil no seu dia a dia, você pode apoiar o desenvolvimento em [Buy Me a Coffee](https://buymeacoffee.com/pablomichelin).

---

## 👤 Autor

Desenvolvido por **Pablo Michelin**.  
Suporte: [pablo@systemup.inf.br](mailto:pablo@systemup.inf.br)
