import React, { useState } from 'react'
import { supabase } from '../lib/supabase'

export default function Login() {
  const [mode, setMode] = useState('login') // 'login' | 'cadastro'
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [senha2, setSenha2] = useState('')
  const [nomeEscritorioInput, setNomeEscritorio] = useState('')
  const [nomeUsuario, setNomeUsuario] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function handleLogin(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    const { error } = await supabase.auth.signInWithPassword({ email, password: senha })
    if (error) setError('E-mail ou senha incorretos.')
    setLoading(false)
  }

  async function handleCadastro(e) {
    e.preventDefault()
    setError('')
    if (senha !== senha2) { setError('As senhas não coincidem.'); return }
    if (!nomeEscritorioInput) { setError('Informe o nome do escritório.'); return }
    setLoading(true)

    // 1. Criar usuário auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password: senha,
    })
    if (authError) { setError(authError.message); setLoading(false); return }

    const userId = authData.user?.id
    if (!userId) { setError('Erro ao criar usuário.'); setLoading(false); return }

    // 2. Criar escritório
    const { data: esc, error: escError } = await supabase
      .from('escritorios')
      .insert({ nome: nomeEscritorioInput })
      .select().single()
    if (escError) { setError(escError.message); setLoading(false); return }

    // 3. Criar perfil do usuário
    const { error: userError } = await supabase
      .from('usuarios')
      .insert({ id: userId, escritorio_id: esc.id, nome: nomeUsuario || email, email, nivel: 'admin' })
    if (userError) { setError(userError.message); setLoading(false); return }

    // 4. Criar grupos padrão
    const gruposPadrao = [
      { nome: 'Lucro Real', descricao: 'Apuração pelo lucro efetivo', ordem: 1 },
      { nome: 'Lucro Presumido', descricao: 'Percentual fixo sobre receita bruta', ordem: 2 },
      { nome: 'Simples Nacional', descricao: 'Regime unificado DAS', ordem: 3 },
      { nome: 'Desenquadrada', descricao: 'Empresa em processo de enquadramento', ordem: 4 },
      { nome: 'SFL', descricao: 'Sem fins lucrativos', ordem: 5 },
      { nome: 'Isenta', descricao: 'Entidade isenta de tributação', ordem: 6 },
      { nome: 'Folha de Pagamento', descricao: 'Apenas gestão de folha', ordem: 7 },
    ]
    await supabase.from('grupos').insert(
      gruposPadrao.map(g => ({ ...g, escritorio_id: esc.id }))
    )

    // 5. Criar competências padrão
    await supabase.from('competencias').insert([
      { escritorio_id: esc.id, ano: 2024, data_inicio: '2024-01-01', data_fim: '2024-12-31', status: 'encerrada' },
      { escritorio_id: esc.id, ano: 2025, data_inicio: '2025-01-01', data_fim: '2025-12-31', status: 'aberta' },
    ])

    setSuccess('Escritório criado! Verifique seu e-mail para confirmar o cadastro.')
    setLoading(false)
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-logo">RF</div>

        {mode === 'login' ? (
          <>
            <div className="login-title">Entrar no sistema</div>
            <div className="login-sub">Acesse sua conta do escritório</div>
            <form onSubmit={handleLogin}>
              <div className="field">
                <label>E-mail</label>
                <input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="contador@escritorio.com.br" required />
              </div>
              <div className="field">
                <label>Senha</label>
                <input type="password" value={senha} onChange={e=>setSenha(e.target.value)} placeholder="••••••••" required />
              </div>
              {error && <div className="error-msg">{error}</div>}
              <button className="btn btn-primary" type="submit" style={{width:'100%',justifyContent:'center',marginTop:8}} disabled={loading}>
                {loading ? 'Entrando...' : 'Entrar'}
              </button>
            </form>
            <div className="login-divider">ou</div>
            <button className="btn" style={{width:'100%',justifyContent:'center'}} onClick={()=>setMode('cadastro')}>
              Cadastrar novo escritório
            </button>
          </>
        ) : (
          <>
            <div className="login-title">Novo escritório</div>
            <div className="login-sub">Preencha os dados para começar</div>
            {success ? (
              <div style={{color: 'var(--green)', fontSize: 13, lineHeight: 1.6}}>{success}
                <br/><button className="btn btn-sm" style={{marginTop:12}} onClick={()=>setMode('login')}>Voltar ao login</button>
              </div>
            ) : (
              <form onSubmit={handleCadastro}>
                <div className="field">
                  <label>Nome do escritório *</label>
                  <input value={nomeEscritorioInput} onChange={e=>setNomeEscritorio(e.target.value)} placeholder="Alva Contabilidade" required />
                </div>
                <div className="field">
                  <label>Seu nome *</label>
                  <input value={nomeUsuario} onChange={e=>setNomeUsuario(e.target.value)} placeholder="Ricardo Fonseca" required />
                </div>
                <div className="field">
                  <label>E-mail *</label>
                  <input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="admin@escritorio.com.br" required />
                </div>
                <div className="field-row field-row-2">
                  <div className="field">
                    <label>Senha *</label>
                    <input type="password" value={senha} onChange={e=>setSenha(e.target.value)} placeholder="mínimo 6 caracteres" required />
                  </div>
                  <div className="field">
                    <label>Confirmar senha *</label>
                    <input type="password" value={senha2} onChange={e=>setSenha2(e.target.value)} placeholder="••••••••" required />
                  </div>
                </div>
                {error && <div className="error-msg">{error}</div>}
                <button className="btn btn-primary" type="submit" style={{width:'100%',justifyContent:'center',marginTop:8}} disabled={loading}>
                  {loading ? 'Criando...' : 'Criar escritório'}
                </button>
                <button type="button" className="btn" style={{width:'100%',justifyContent:'center',marginTop:8}} onClick={()=>setMode('login')}>
                  Voltar ao login
                </button>
              </form>
            )}
          </>
        )}
      </div>
    </div>
  )
}
