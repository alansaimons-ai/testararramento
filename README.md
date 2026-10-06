# Painel de Indicadores — V.tal / CGR

Site estático (um único `index.html`) + banco no Supabase. Hospedagem: Vercel (deploy automático a cada push no GitHub).

## Como o histórico funciona
- **BA é a chave de tudo.** Cada upload SOMA ao banco; nunca duplica.
  - **Prazo e Reincidência** (`ba_prazo`, chave `nu_documento`): BA novo entra, repetido é ignorado.
  - **COF > Visão histórica** (`ba_cof_hist`, chave `ba_final`): BA novo entra; BA existente é atualizado (ex.: ganhou `sent_date`). Um BA já encerrado **não é reaberto** por um arquivo mais antigo.
  - **Barramento** — BAs abertos (`ba_abertos`, chave `nu_documento`): cada upload é um "lote"; o lote mais recente é a foto dos abertos, os anteriores ficam de histórico. Trechos VSAO (`barr_trechos`): o upload novo substitui o anterior.
  - **Preenchimentos manuais** (trecho afetado, previsão) ficam em `ba_manual`, por BA — um upload novo não apaga o que a equipe digitou.
- Os botões "Limpar / Nova base" só limpam a tela; os dados continuam no banco (F5 recarrega). Não há permissão de apagar histórico pelo painel.
- Sem a chave do Supabase preenchida, o painel roda em **modo local** (dados só no navegador).

## Passo a passo (uma vez)
1. **Banco:** Supabase → *SQL Editor* → *New query* → cole o conteúdo de `supabase/schema.sql` → *Run*.
2. **Usuários:** Supabase → *Authentication → Users → Add user* (e-mail + senha, marque *Auto Confirm*). Em *Authentication → Providers → Email* desligue *Allow new users to sign up* para só entrar quem você cadastrou.
3. **Chave:** Supabase → *Project Settings → API* → copie a chave **anon / publishable** (NUNCA a `service_role`). No `index.html`, procure `CLOUD_CFG` e troque `COLE_AQUI_A_CHAVE_PUBLICA_ANON` pela chave. (A chave anon é pública por desenho; quem protege os dados é o login + as regras RLS do `schema.sql`.)
4. **Publicar:** `git add . && git commit -m "painel" && git push` — o Vercel publica sozinho.

## Alterações futuras
Mudanças no painel = editar o `index.html`, commit, push. O Vercel republica em ~1 minuto. Nenhum crédito de plataforma envolvido.
