-- =============================================
-- SISTEMA GERENCIAL CONTÁBIL — SCHEMA SUPABASE
-- Execute no SQL Editor do Supabase
-- =============================================

-- 1. ESCRITÓRIOS
create table escritorios (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cnpj text,
  crc text,
  telefone text,
  email text,
  endereco text,
  plano text default 'profissional',
  created_at timestamptz default now()
);

-- 2. USUÁRIOS (extende auth.users do Supabase)
create table usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  escritorio_id uuid references escritorios(id) on delete cascade,
  nome text not null,
  email text not null,
  nivel text default 'contador' check (nivel in ('admin','contador','visualizador')),
  ativo boolean default true,
  created_at timestamptz default now()
);

-- 3. GRUPOS / REGIMES TRIBUTÁRIOS
create table grupos (
  id uuid primary key default gen_random_uuid(),
  escritorio_id uuid references escritorios(id) on delete cascade,
  nome text not null,
  descricao text,
  ordem int default 0,
  created_at timestamptz default now()
);

-- Grupos padrão (inseridos via trigger ou manualmente)

-- 4. COMPETÊNCIAS (anos fiscais)
create table competencias (
  id uuid primary key default gen_random_uuid(),
  escritorio_id uuid references escritorios(id) on delete cascade,
  ano int not null,
  data_inicio date,
  data_fim date,
  status text default 'aberta' check (status in ('aberta','encerrada','planejamento')),
  created_at timestamptz default now(),
  unique(escritorio_id, ano)
);

-- 5. CLIENTES
create table clientes (
  id uuid primary key default gen_random_uuid(),
  escritorio_id uuid references escritorios(id) on delete cascade,
  codigo int,
  nome text not null,
  cnpj text,
  cfdf text,
  uf text default 'DF',
  atividade text,
  movimentacao text default 'M' check (movimentacao in ('M','SM')),

  -- Regime
  grupo_id uuid references grupos(id),
  regime_nome text, -- cache do nome para exibição rápida

  -- Status
  status text default 'Ativa' check (status in ('Ativa','Distrato','Baixada')),
  data_entrada date,
  data_saida date,
  obs_saida text,

  -- Responsáveis
  resp_fiscal text,
  resp_folha text,
  resp_contabil text,
  resp_exec_contabil text,

  -- Tributário
  peso text,
  fator_r boolean default false,
  nivel_documental text,
  retencoes boolean default false,

  -- Flags
  ativo boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 6. SÓCIOS
create table socios (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid references clientes(id) on delete cascade,
  nome text not null,
  cpf text,
  percentual_participacao numeric(5,2),
  prolabore numeric(15,2),
  distribuicao_lucros numeric(15,2),
  data_distribuicao date,
  created_at timestamptz default now()
);

-- 7. ECD / ECF por competência
create table obrigacoes_fiscais (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid references clientes(id) on delete cascade,
  competencia_ano int not null,
  tipo text not null check (tipo in ('ECD','ECF')),
  transmitida boolean default false,
  data_transmissao date,
  numero_recibo text,
  arquivo_nome text,
  observacao text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(cliente_id, competencia_ano, tipo)
);

-- 8. HISTÓRICO / OCORRÊNCIAS
create table historico_clientes (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid references clientes(id) on delete cascade,
  usuario_id uuid references usuarios(id),
  descricao text not null,
  created_at timestamptz default now()
);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

alter table escritorios enable row level security;
alter table usuarios enable row level security;
alter table grupos enable row level security;
alter table competencias enable row level security;
alter table clientes enable row level security;
alter table socios enable row level security;
alter table obrigacoes_fiscais enable row level security;
alter table historico_clientes enable row level security;

-- Usuários só veem dados do próprio escritório
create policy "usuarios_escritorio" on usuarios
  for all using (escritorio_id = (
    select escritorio_id from usuarios where id = auth.uid()
  ));

create policy "grupos_escritorio" on grupos
  for all using (escritorio_id = (
    select escritorio_id from usuarios where id = auth.uid()
  ));

create policy "competencias_escritorio" on competencias
  for all using (escritorio_id = (
    select escritorio_id from usuarios where id = auth.uid()
  ));

create policy "clientes_escritorio" on clientes
  for all using (escritorio_id = (
    select escritorio_id from usuarios where id = auth.uid()
  ));

create policy "socios_via_cliente" on socios
  for all using (
    cliente_id in (
      select id from clientes where escritorio_id = (
        select escritorio_id from usuarios where id = auth.uid()
      )
    )
  );

create policy "obrigacoes_via_cliente" on obrigacoes_fiscais
  for all using (
    cliente_id in (
      select id from clientes where escritorio_id = (
        select escritorio_id from usuarios where id = auth.uid()
      )
    )
  );

create policy "historico_via_cliente" on historico_clientes
  for all using (
    cliente_id in (
      select id from clientes where escritorio_id = (
        select escritorio_id from usuarios where id = auth.uid()
      )
    )
  );

-- =============================================
-- FUNÇÃO: updated_at automático
-- =============================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger clientes_updated_at before update on clientes
  for each row execute function set_updated_at();

create trigger obrigacoes_updated_at before update on obrigacoes_fiscais
  for each row execute function set_updated_at();
