# VendaIA

Site comercial e base do SaaS de atendimento inteligente.

## Planos

- **Start:** R$ 97/mês
- **Pro:** R$ 297/mês
- **Implantação:** cobrada separadamente, conforme proposta.

## Desenvolvimento

```bash
npm install
npm run dev
npm run build
```

Configure `VITE_SALES_WHATSAPP` no `.env` (somente números com DDI 55).

## Estado

O site apresenta planos, recursos, demonstração simulada e formulário de contato. Pagamentos recorrentes, painel de usuários, IA real e integração com WhatsApp ainda precisam ser implementados. Não coloque chaves privadas no frontend.

## Arquitetura

React + TypeScript + Vite no frontend. Planejado Supabase com multi-tenant/RLS, backend seguro para OpenAI e WhatsApp e gateway de pagamento via webhook verificado.