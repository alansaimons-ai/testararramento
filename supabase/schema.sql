-- =====================================================================
--  Painel de Indicadores V.tal / CGR — banco de dados (Supabase / Postgres)
--  Rode UMA vez: Supabase > SQL Editor > New query > cole tudo > Run
--  Regra de ouro: o BA é a chave primária de todas as tabelas de BA.
--  Subir um arquivo de novo nunca duplica: BA novo entra, BA existente é atualizado.
-- =====================================================================

-- Aba PRAZO E REINCIDÊNCIA — chave: nu_documento (campo "doc"). Histórico acumulado; BA repetido é ignorado.
create table if not exists public.ba_prazo (
  doc        text primary key,
  dados      jsonb       not null,
  criado_em  timestamptz not null default now()
);

-- Aba COF > Visão histórica — chave: ba_final. BA existente é atualizado (ex.: ganhou encerramento).
create table if not exists public.ba_cof_hist (
  ba             text primary key,
  dados          jsonb       not null,
  atualizado_em  timestamptz not null default now()
);

-- Aba BARRAMENTO — BAs abertos do portal Desempenho IE. Chave: nu_documento.
-- "lote" = data/hora do upload. A foto atual dos abertos = o lote mais recente; o restante fica como histórico.
create table if not exists public.ba_abertos (
  ba     text primary key,
  lote   timestamptz not null,
  dados  jsonb       not null
);
create index if not exists ba_abertos_lote_idx on public.ba_abertos (lote desc);

-- Aba BARRAMENTO — trechos da base VSAO (foto atual; o upload novo substitui o anterior).
create table if not exists public.barr_trechos (
  chave  text primary key,          -- TRECHO|SENTIDO
  lote   timestamptz not null,
  dados  jsonb       not null
);

-- Preenchimentos manuais por BA (trecho afetado / previsão de correção). Ficam separados
-- para que um upload novo NUNCA apague o que a equipe digitou.
create table if not exists public.ba_manual (
  ba             text primary key,
  trecho         text,
  previsao       text,
  atualizado_em  timestamptz not null default now(),
  atualizado_por text
);

-- Metadados (estado do histórico, informações do último upload etc.)
create table if not exists public.app_meta (
  k  text primary key,
  v  jsonb
);

-- ---------------------------------------------------------------------
--  Segurança: só usuário LOGADO (authenticated) lê e grava. Visitante anônimo não acessa nada.
--  Não há permissão de DELETE nas tabelas de histórico (ba_prazo, ba_cof_hist, ba_abertos),
--  para ninguém apagar o histórico por engano. Se precisar zerar, faça pelo SQL Editor.
-- ---------------------------------------------------------------------
alter table public.ba_prazo     enable row level security;
alter table public.ba_cof_hist  enable row level security;
alter table public.ba_abertos   enable row level security;
alter table public.barr_trechos enable row level security;
alter table public.ba_manual    enable row level security;
alter table public.app_meta     enable row level security;

revoke all on public.ba_prazo, public.ba_cof_hist, public.ba_abertos, public.barr_trechos, public.ba_manual, public.app_meta from anon;

grant select, insert                 on public.ba_prazo     to authenticated;
grant select, insert, update         on public.ba_cof_hist  to authenticated;
grant select, insert, update         on public.ba_abertos   to authenticated;
grant select, insert, update, delete on public.barr_trechos to authenticated;
grant select, insert, update         on public.ba_manual    to authenticated;
grant select, insert, update         on public.app_meta     to authenticated;

drop policy if exists p_prazo_sel   on public.ba_prazo;     create policy p_prazo_sel   on public.ba_prazo     for select to authenticated using (true);
drop policy if exists p_prazo_ins   on public.ba_prazo;     create policy p_prazo_ins   on public.ba_prazo     for insert to authenticated with check (true);

drop policy if exists p_cof_sel     on public.ba_cof_hist;  create policy p_cof_sel     on public.ba_cof_hist  for select to authenticated using (true);
drop policy if exists p_cof_ins     on public.ba_cof_hist;  create policy p_cof_ins     on public.ba_cof_hist  for insert to authenticated with check (true);
drop policy if exists p_cof_upd     on public.ba_cof_hist;  create policy p_cof_upd     on public.ba_cof_hist  for update to authenticated using (true) with check (true);

drop policy if exists p_abertos_sel on public.ba_abertos;   create policy p_abertos_sel on public.ba_abertos   for select to authenticated using (true);
drop policy if exists p_abertos_ins on public.ba_abertos;   create policy p_abertos_ins on public.ba_abertos   for insert to authenticated with check (true);
drop policy if exists p_abertos_upd on public.ba_abertos;   create policy p_abertos_upd on public.ba_abertos   for update to authenticated using (true) with check (true);

drop policy if exists p_trechos_sel on public.barr_trechos; create policy p_trechos_sel on public.barr_trechos for select to authenticated using (true);
drop policy if exists p_trechos_ins on public.barr_trechos; create policy p_trechos_ins on public.barr_trechos for insert to authenticated with check (true);
drop policy if exists p_trechos_upd on public.barr_trechos; create policy p_trechos_upd on public.barr_trechos for update to authenticated using (true) with check (true);
drop policy if exists p_trechos_del on public.barr_trechos; create policy p_trechos_del on public.barr_trechos for delete to authenticated using (true);

drop policy if exists p_manual_sel  on public.ba_manual;    create policy p_manual_sel  on public.ba_manual    for select to authenticated using (true);
drop policy if exists p_manual_ins  on public.ba_manual;    create policy p_manual_ins  on public.ba_manual    for insert to authenticated with check (true);
drop policy if exists p_manual_upd  on public.ba_manual;    create policy p_manual_upd  on public.ba_manual    for update to authenticated using (true) with check (true);

drop policy if exists p_meta_sel    on public.app_meta;     create policy p_meta_sel    on public.app_meta     for select to authenticated using (true);
drop policy if exists p_meta_ins    on public.app_meta;     create policy p_meta_ins    on public.app_meta     for insert to authenticated with check (true);
drop policy if exists p_meta_upd    on public.app_meta;     create policy p_meta_upd    on public.app_meta     for update to authenticated using (true) with check (true);
