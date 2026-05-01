# Sistema Gerencial Contábil

Sistema web para controle contábil de clientes, multi-escritório, com ECD/ECF, sócios e histórico.

---

## Como colocar no ar (passo a passo — sem instalação local)

### 1. Criar conta no Supabase (banco de dados + autenticação)
1. Acesse https://supabase.com e crie uma conta gratuita
2. Clique em **"New project"**, dê um nome (ex: "contabil") e escolha uma senha forte
3. Aguarde o projeto criar (~2 minutos)
4. Vá em **Settings > API** e copie:
   - **Project URL** (ex: `https://abcxyz.supabase.co`)
   - **anon public key**

### 2. Criar as tabelas no Supabase
1. No painel do Supabase, clique em **SQL Editor**
2. Clique em **"New query"**
3. Cole todo o conteúdo do arquivo `supabase_schema.sql` (está na pasta do projeto)
4. Clique em **"Run"**
5. Todas as tabelas serão criadas automaticamente

### 3. Subir o código para o GitHub
1. Acesse https://github.com e crie uma conta se não tiver
2. Clique em **"New repository"**, dê o nome "contabil-system", clique em **"Create"**
3. Faça upload de todos os arquivos desta pasta para o repositório
   - Clique em **"uploading an existing file"**
   - Selecione todos os arquivos e pastas (src, public, package.json, etc.)
   - **Não inclua** o arquivo `.env` (apenas `.env.example`)
4. Clique em **"Commit changes"**

### 4. Deploy na Vercel (hospedagem gratuita)
1. Acesse https://vercel.com e crie uma conta com seu GitHub
2. Clique em **"New Project"**
3. Selecione o repositório "contabil-system"
4. Antes de clicar em Deploy, clique em **"Environment Variables"** e adicione:
   - Nome: `REACT_APP_SUPABASE_URL` → Valor: sua Project URL do Supabase
   - Nome: `REACT_APP_SUPABASE_ANON_KEY` → Valor: sua anon key do Supabase
5. Clique em **"Deploy"**
6. Em ~3 minutos o sistema estará no ar com uma URL do tipo `contabil-system.vercel.app`

### 5. Primeiro acesso
1. Acesse a URL gerada pela Vercel
2. Clique em **"Cadastrar novo escritório"**
3. Preencha o nome do escritório e seus dados de acesso
4. O sistema criará automaticamente:
   - Os grupos de regimes padrão (Lucro Real, Presumido, Simples Nacional, etc.)
   - As competências 2024 e 2025
5. Pronto! Você pode começar a cadastrar clientes

---

## Estrutura do projeto

```
src/
  App.js              — Roteamento principal
  App.css             — Estilos globais
  lib/
    supabase.js       — Conexão com o banco
  pages/
    Login.js          — Tela de login e cadastro de escritório
    Dashboard.js      — Painel com métricas
    Clientes.js       — Lista de clientes com filtros
    ClienteFicha.js   — Ficha completa do cliente (5 abas)
    Usuarios.js       — Usuários, Competências e Grupos
  components/
    Layout.js         — Sidebar + estrutura de navegação

supabase_schema.sql   — Script SQL para criar as tabelas
```

## Funcionalidades

- **Multi-escritório** — cada escritório vê apenas seus próprios dados
- **Login** com e-mail e senha (Supabase Auth)
- **Clientes** — código, razão social, CNPJ, regime, status (ativa/distrato/baixada), responsáveis, entrada/saída
- **Busca** por código, CNPJ ou descrição
- **Filtros** por regime, status, responsável, ECD e ECF
- **Ficha completa** com 5 abas: Cadastro, Tributário, Sócios, ECD/ECF, Histórico
- **Sócios** — nome, CPF, % participação, pró-labore, distribuição de lucros
- **ECD/ECF** — controle por competência (ano) com número de recibo
- **Histórico** — registro de ocorrências com data e usuário
- **Grupos/Regimes** — configuráveis pelo escritório
- **Competências** — criação e encerramento de anos fiscais
- **Usuários** — admin, contador, visualizador

## Adicionar mais usuários ao escritório

Por limitação do Supabase no plano gratuito, novos usuários devem criar conta pelo link de cadastro do sistema e depois você vincula o escritório_id manualmente pelo SQL Editor do Supabase, ou use o fluxo de invite (requer plano pago do Supabase).

Alternativa gratuita: cada usuário novo acessa o sistema, cria um "escritório" com nome qualquer, e você atualiza o `escritorio_id` na tabela `usuarios` via SQL Editor para apontar para o escritório correto.
