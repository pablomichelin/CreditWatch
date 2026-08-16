# Integrações automáticas

## Regra de produto

Adicionar uma IA cria um conector, não um campo para digitação. O app deve
permitir que o usuário autentique a conta numa janela visível e deve ler apenas
dados de plano, consumo e renovação necessários ao monitoramento.

## Dados esperados

| Provedor | Dados exibidos |
|---|---|
| Cursor | Plano; data de reset; Cursor Models; Other Models; On-Demand usado e limite |
| Codex | Plano; saldo de créditos; limite semanal restante; data/hora de redefinição |
| Claude | Limite e janela de renovação informados pelo painel da conta |
| Gemini | Plano e dados de quota/uso mostrados no painel Google Developers |
| Antigravity | Gemini semanal/5h; Claude e GPT semanal/5h; respectivos resets |

## Implementação segura

1. Buscar uma API oficial/OAuth do provedor. Esta é a integração preferida.
2. Se não houver API pública, oferecer uma janela de login por provedor e
   documentar explicitamente a leitura do painel, com aprovação no app.
3. Nunca ler a base de senhas do navegador ou cookies de outros aplicativos.
   Uma integração local privada exige autorização explícita, acesso somente
   de leitura e credenciais efêmeras mantidas apenas em memória.
4. Guardar em Keychain apenas um token OAuth que o próprio provedor tenha
   entregue ao CreditWatch; nunca a senha da conta.

## Estado atual

A versão `0.11.0` mantém uma sessão visível e separada por provedor. Depois
da primeira conexão, atualiza ao iniciar, ao abrir a prévia, ao voltar do
repouso e a cada 60 segundos.

- **Cursor:** lê Cursor Models, Other Models e On-Demand.
- **Codex:** lê o percentual restante, reset e saldo de créditos.
- **Antigravity:** lê os quatro medidores reais do serviço local do aplicativo;
  o token efêmero autorizado nunca é persistido.

Não é feita leitura de senha, Keychain ou cookies de outros navegadores.
