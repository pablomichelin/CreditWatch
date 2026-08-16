# CreditWatch v0.11.3

Desenvolvido por Pablo Michelin.

App de barra do macOS para acompanhar créditos, percentuais e datas de
renovação de ferramentas de IA. A versão atual inclui uma janela de login
visível para cada provedor e lê dados somente depois que você autorizar e
abrir o painel correspondente.

O Google AI Studio fornece os medidores RPM, TPM e RPD do Gemini. O
Antigravity usa outra fonte: quando o aplicativo está aberto, o CreditWatch
lê localmente os quatro limites mostrados em Models & Usage (Gemini semanal
e 5h; Claude/GPT semanal e 5h). O token temporário dessa consulta fica apenas
em memória e não é salvo.

ChatGPT e Codex aparecem como contas diferentes. O ChatGPT exibe o plano e
os limites que a própria interface publicar; como os limites comuns variam
por modelo e recurso, o app não inventa um percentual global quando ele não
existe no painel.

O Grok abre diretamente Settings → Usage e acompanha o saldo semanal
compartilhado dos planos SuperGrok. Em contas Free, o app mantém explícito
quando não existe um percentual semanal publicado.

Requer macOS Sonoma (14) ou mais recente.

## Construir e instalar

```bash
cd ~/Documents/IA-Local-Pablo/CreditWatch
bash Scripts/install.sh
```

O instalador coloca o app em `~/Applications`, abre-o e permite marcar
**Abrir CreditWatch ao iniciar sessão** em Configurar.

## Uso

Clique no ícone de medidor na barra e abra **Configurar**. Em cada IA, use
**Conectar**: o login abre dentro do CreditWatch e fica salvo apenas neste Mac.
Depois, o app abre o painel e atualiza os números visíveis. Não há extensão de
navegador, configuração do Safari ou instalação extra.
Depois da primeira conexão, a atualização ocorre ao iniciar, ao abrir a
prévia, ao voltar do repouso e a cada 60 segundos. O Antigravity precisa estar
aberto para fornecer seus limites locais.
As informações extraídas são salvas apenas em
`~/Library/Application Support/CreditWatch/usage.json`.

## Integrações futuras

Integrações automáticas serão adicionadas somente por API oficial, OAuth,
painel autenticado dentro do próprio CreditWatch ou integração local que o
usuário autorize explicitamente. O app não lê senhas nem cookies de outros
navegadores.
