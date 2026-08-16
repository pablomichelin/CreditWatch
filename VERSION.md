# CreditWatch

Versão visual: `0.11.3`  
Desenvolvido por Pablo Michelin.

## 0.11.3

- exibe o indicador 'Conectado' com ícone de confirmação para contas já autenticadas;
- altera o botão de ação para 'Reconectar' quando a conta estiver conectada;
- padroniza User-Agent de desktop oficial para todas as consultas em segundo plano, contornando bloqueios dinâmicos;
- aprimora o polling de leitura contínua para captura rápida de métricas em SPAs (ChatGPT, Codex, Cursor e Gemini).

## 0.11.2

- adiciona suporte dinâmico a modelos Gemini (1.5 Flash, 2.0 Flash, 2.5 Flash) no Google AI Studio;
- estende a leitura do Antigravity para compatibilidade com arquiteturas Intel e Apple Silicon;
- aprimora o parsing de datas de renovação em português e inglês (meses por extenso e horários);
- ajusta o manifest da extensão Chromium para total conformidade com o Manifest V3;
- otimiza o frame do WebKit em segundo plano e previne alertas de codesign no empacotamento.

## 0.11.1

- reorganiza as opções do aplicativo em um cartão minimalista;
- alinha o switch de inicialização e transforma o reporte de erro em uma ação discreta;
- centraliza a identificação da versão no rodapé das configurações.

## 0.11.0

- atualiza automaticamente ao iniciar, abrir a prévia, voltar do repouso e a cada 60 segundos;
- corrige o endereço oficial de Uso do Codex e passa a mostrar também o saldo de créditos;
- substitui os três medidores incorretos do Antigravity pelos quatro limites reais: Gemini semanal/5h e Claude-GPT semanal/5h;
- lê os limites diretamente do serviço local do Antigravity, sem salvar senha ou token;
- registra o horário da última leitura e nunca usa novamente os números do AI Studio como se fossem do Antigravity.

## 0.10.0

- adiciona Grok com login no painel oficial de Usage;
- lê o percentual semanal usado e o converte em percentual restante;
- mostra o plano Grok e a data de reset quando estiverem publicados no painel.
- simplifica a lista da barra superior e reúne as ações em um rodapé minimalista.

## 0.9.0

- separa ChatGPT de Codex e adiciona login próprio para o uso comum;
- mostra o plano do ChatGPT e informa honestamente quando não existe um percentual único publicado;
- usa o esquema de composição do Outlook para preencher destinatário, assunto e corpo.

## 0.8.0

- Reportar erro abre uma nova mensagem no Outlook, quando instalado, já endereçada a pablo@systemup.inf.br;
- remove a opção sem integração “Outro”, inclusive de configurações antigas;
- adiciona Antigravity com leitura de RPM, TPM e RPD no Google AI Studio.

## 0.7.7

- duplo clique abre as configurações pelo mecanismo oficial do SwiftUI.

## 0.7.6

- duplo clique na barra superior tratado pelo evento nativo do macOS.

## 0.7.5

- configurações mais altas, sem cortar o rodapé;
- duplo clique no ícone da barra superior abre diretamente as configurações.

## 0.7.4

- descrições dos medidores aparecem ao lado da conta, mantendo todas as linhas com a mesma altura.

## 0.7.3

- mantém os medidores visíveis na prévia compacta, com altura fixa e rolagem.

## 0.7.2

- botão Reportar erro abre o e-mail padrão para pablo@systemup.inf.br com a versão no assunto.

## 0.7.1

- preserva os dados coletados quando há uma IA personalizada na lista.

## 0.7.0

- painel da barra superior mais compacto e com rolagem interna;
- ícone do Dock some quando todas as janelas são fechadas;
- Cursor On-Demand mostra saldo monetário disponível e não herda o reset das cotas incluídas.

## 0.6.2

- leitura das cotas RPM, TPM e RPD no formato atual do Google AI Studio;
- atualização automática repetida enquanto painéis dinâmicos terminam de carregar.

## 0.6.1

- leitura do formato decimal usado atualmente no painel do Cursor.

## 0.6.0

- versão exibida vem do pacote do aplicativo;
- Cursor abre diretamente Billing e lê Models, Other Models e On-Demand;
- Gemini abre Rate Limits e lê RPM, TPM e RPD;
- Claude informa o plano publicado sem inventar percentual inexistente.

## 0.5.0

- login e consulta dentro do próprio CreditWatch;
- não exige extensão de navegador.

## 0.4.0

- conectores separados para Chromium, Firefox e Safari;
- mesma leitura local para os navegadores suportados.

## 0.3.0

- contas agrupadas por provedor;
- porcentagens e reset somente de leitura;
- barras mostram saldo restante;
- instalação em Aplicativos e início automático;
- ícone e extensão local do Chrome.
