# Arquitetura do SaaS VendaIA

## Modelo de negócio
Planos **Start (R$ 97/mês)** e **Pro (R$ 297/mês)** com taxa de implantação à parte, definida em orçamento. Valores podem ser alterados no painel de gestão futuro.

## Componentes
- **Frontend:** React, TypeScript, Vite, Vercel.
- **Identidade e persistência:** Supabase Auth + Postgres.
- **Multiempresa:** organizações, membros por organização, agentes, contatos, conversas e mensagens filtrados por `organization_id`, com RLS.
- **Motor de IA:** serviço backend autenticado, com chaves de IA somente no servidor, limite de mensagens por plano e registros de uso.
- **WhatsApp:** provedor autorizado, webhook validado e tratamento de mensagens idempotente.
- **Cobrança:** provedor de pagamentos com cliente, assinatura, taxa de implantação e webhook com verificação de assinatura. O backend é a fonte de verdade do status.

## Fluxo de adesão
1. Empresa solicita plano e recebe proposta de implantação.
2. Checkout seguro criado no backend; taxas e preço recorrente são discriminados.
3. Webhook confirmado habilita a assinatura e cria a organização.
4. Proprietário configura agente e integração WhatsApp.
5. Mensagens são processadas no backend, isoladas por empresa.
6. Falha/cancelamento altera o status somente após reconciliação do gateway.

## Segurança
- Nunca enviar chave `service_role`, chave privada de gateway ou OpenAI para o navegador.
- Habilitar RLS em todas as tabelas públicas.
- Verificar acesso por membro da organização e papel, não por metadados editáveis de usuário.
- Impor limites de uso e cobrança no servidor.
- Implementar consentimento, retenção e exclusão conforme LGPD.
- Não executar as migrações em produção sem revisão, testes e configuração de Auth.

## Situação
Esta entrega contém o site comercial e um esquema inicial de dados. **Não** contém checkout ativo, login, painel funcional, integração real com IA ou WhatsApp. 
