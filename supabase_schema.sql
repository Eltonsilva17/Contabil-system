import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import { Plus, Trash2, ArrowLeft, Save } from 'lucide-react'

const ANOS = [2023, 2024, 2025]

export default function ClienteFicha() {
  const { id } = useParams()
  const navigate = useNavigate()
  const isNew = !id || id === 'novo'

  const [tab, setTab] = useState('cadastro')
  const [loading, setLoading] = useState(!isNew)
  const [saving, setSaving] = useState(false)
  const [grupos, setGrupos] = useState([])
  const [responsaveis, setResponsaveis] = useState([])
  const [escritorioId, setEscritorioId] = useState(null)

  // Form state
  const [form, setForm] = useState({
    codigo: '', nome: '', cnpj: '', cfdf: '', uf: 'DF',
    atividade: '', movimentacao: 'M', status: 'Ativa',
    data_entrada: '', data_saida: '', obs_saida: '',
    grupo_id: '', regime_nome: '',
    peso: '', fator_r: false, nivel_documental: '', retencoes: false,
    resp_fiscal: '', resp_folha: '', resp_contabil: '', resp_exec_contabil: '',
  })
  const [socios, setSocios] = useState([])
  const [obrigacoes, setObrigacoes] = useState({})
  const [historico, setHistorico] = useState([])
  const [novaObs, setNovaObs] = useState('')
  const [clienteId, setClienteId] = useState(null)

  useEffect(() => {
    async function init() {
      const { data: u } = await supabase.from('usuarios')
        .select('escritorio_id').eq('id', (await supabase.auth.getUser()).data.user.id).single()
      if (!u) return
      setEscritorioId(u.escritorio_id)

      const { data: g } = await supabase.from('grupos')
        .select('id,nome').eq('escritorio_id', u.escritorio_id).order('ordem')
      setGrupos(g || [])

      // Build responsaveis list
      const { data: cl } = await supabase.from('clientes')
        .select('resp_fiscal,resp_folha,resp_contabil,resp_exec_contabil')
        .eq('escritorio_id', u.escritorio_id)
      const all = new Set(['DANIEL','BRUNA','LUCAS','GUILHERME','SOUSA','DAVI','TARICK','RAIANE','AMANDA','LUCAS PAIXÃO','RAQUEL','CARLENE'])
      cl?.forEach(c => {
        [c.resp_fiscal,c.resp_folha,c.resp_contabil,c.resp_exec_contabil].filter(Boolean).forEach(r=>all.add(r))
      })
      setResponsaveis([...all].sort())

      if (!isNew) {
        const { data: c } = await supabase.from('clientes').select('*').eq('id', id).single()
        if (c) {
          setClienteId(c.id)
          setForm({
            codigo: c.codigo || '', nome: c.nome || '', cnpj: c.cnpj || '',
            cfdf: c.cfdf || '', uf: c.uf || 'DF', atividade: c.atividade || '',
            movimentacao: c.movimentacao || 'M', status: c.status || 'Ativa',
            data_entrada: c.data_entrada || '', data_saida: c.data_saida || '',
            obs_saida: c.obs_saida || '', grupo_id: c.grupo_id || '',
            regime_nome: c.regime_nome || '', peso: c.peso || '',
            fator_r: c.fator_r || false, nivel_documental: c.nivel_documental || '',
            retencoes: c.retencoes || false, resp_fiscal: c.resp_fiscal || '',
            resp_folha: c.resp_folha || '', resp_contabil: c.resp_contabil || '',
            resp_exec_contabil: c.resp_exec_contabil || '',
          })
          const { data: s } = await supabase.from('socios').select('*').eq('cliente_id', id).order('created_at')
          setSocios(s || [])
          const { data: o } = await supabase.from('obrigacoes_fiscais').select('*').eq('cliente_id', id)
          const map = {}
          o?.forEach(ob => { map[`${ob.tipo}-${ob.competencia_ano}`] = ob })
          setObrigacoes(map)
          const { data: h } = await supabase.from('historico_clientes').select('*,usuarios(nome)').eq('cliente_id', id).order('created_at', {ascending:false})
          setHistorico(h || [])
        }
      }
      setLoading(false)
    }
    init()
  }, [id, isNew])

  function setF(field, val) { setForm(f => ({ ...f, [field]: val })) }

  async function handleSave() {
    if (!form.nome) { alert('Informe a razão social.'); return }
    setSaving(true)
    const payload = {
      ...form,
      escritorio_id: escritorioId,
      codigo: parseInt(form.codigo) || null,
      regime_nome: grupos.find(g => g.id === form.grupo_id)?.nome || form.regime_nome,
      data_entrada: form.data_entrada || null,
      data_saida: form.data_saida || null,
    }
    let cid = clienteId
    if (isNew) {
      const { data, error } = await supabase.from('clientes').insert(payload).select().single()
      if (error) { alert('Erro ao salvar: ' + error.message); setSaving(false); return }
      cid = data.id
      setClienteId(cid)
    } else {
      const { error } = await supabase.from('clientes').update(payload).eq('id', clienteId)
      if (error) { alert('Erro ao salvar: ' + error.message); setSaving(false); return }
    }
    setSaving(false)
    navigate('/clientes')
  }

  async function addSocio() {
    if (!clienteId) { alert('Salve o cliente primeiro antes de adicionar sócios.'); return }
    const { data } = await supabase.from('socios').insert({ cliente_id: clienteId, nome: '' }).select().single()
    if (data) setSocios(s => [...s, data])
  }
  async function updateSocio(idx, field, val) {
    const s = [...socios]; s[idx] = { ...s[idx], [field]: val }; setSocios(s)
    if (s[idx].id) await supabase.from('socios').update({ [field]: val }).eq('id', s[idx].id)
  }
  async function removeSocio(idx) {
    const s = socios[idx]
    if (s.id) await supabase.from('socios').delete().eq('id', s.id)
    setSocios(prev => prev.filter((_, i) => i !== idx))
  }

  async function toggleObrig(tipo, ano, val) {
    const key = `${tipo}-${ano}`
    const existing = obrigacoes[key]
    if (existing) {
      await supabase.from('obrigacoes_fiscais').update({ transmitida: val }).eq('id', existing.id)
      setObrigacoes(o => ({ ...o, [key]: { ...existing, transmitida: val } }))
    } else {
      if (!clienteId) { alert('Salve o cliente primeiro.'); return }
      const { data } = await supabase.from('obrigacoes_fiscais').insert({
        cliente_id: clienteId, competencia_ano: ano, tipo, transmitida: val
      }).select().single()
      if (data) setObrigacoes(o => ({ ...o, [key]: data }))
    }
  }
  async function setRecibo(tipo, ano) {
    const n = window.prompt(`Número / nome do recibo ${tipo} ${ano}:`)
    if (!n) return
    const key = `${tipo}-${ano}`
    const existing = obrigacoes[key]
    if (existing) {
      await supabase.from('obrigacoes_fiscais').update({ numero_recibo: n }).eq('id', existing.id)
      setObrigacoes(o => ({ ...o, [key]: { ...existing, numero_recibo: n } }))
    } else {
      if (!clienteId) { alert('Salve o cliente primeiro.'); return }
      const { data } = await supabase.from('obrigacoes_fiscais').insert({
        cliente_id: clienteId, competencia_ano: ano, tipo, numero_recibo: n
      }).select().single()
      if (data) setObrigacoes(o => ({ ...o, [key]: data }))
    }
  }

  async function addObs() {
    if (!novaObs.trim() || !clienteId) return
    const { data: u } = await supabase.auth.getUser()
    const { data } = await supabase.from('historico_clientes').insert({
      cliente_id: clienteId, usuario_id: u.user.id, descricao: novaObs
    }).select('*,usuarios(nome)').single()
    if (data) setHistorico(h => [data, ...h])
    setNovaObs('')
  }

  const respOpts = (
    <>
      <option value="">—</option>
      {responsaveis.map(r => <option key={r} value={r}>{r}</option>)}
    </>
  )

  if (loading) return <div className="page-content"><p style={{color:'var(--text-muted)'}}>Carregando...</p></div>

  return (
    <>
      <div className="page-header">
        <div style={{display:'flex', alignItems:'center', gap:12}}>
          <button className="btn btn-sm" onClick={() => navigate('/clientes')}>
            <ArrowLeft size={14}/> Voltar
          </button>
          <div>
            <div className="page-title">{isNew ? 'Novo cliente' : form.nome || 'Ficha do cliente'}</div>
            {!isNew && <div className="page-subtitle">Código #{form.codigo}</div>}
          </div>
        </div>
        <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
          <Save size={14}/> {saving ? 'Salvando...' : 'Salvar'}
        </button>
      </div>

      <div className="page-content">
        <div className="card">
          <div className="tabs" style={{padding:'0 20px'}}>
            {['cadastro','tributario','socios','ecd_ecf','historico'].map(t => (
              <button key={t} className={`tab-btn${tab===t?' active':''}`} onClick={()=>setTab(t)}>
                {t==='cadastro'?'Cadastro':t==='tributario'?'Tributário':t==='socios'?'Sócios':t==='ecd_ecf'?'ECD / ECF':'Histórico'}
              </button>
            ))}
          </div>

          <div style={{padding: '20px 24px'}}>

            {/* TAB CADASTRO */}
            {tab === 'cadastro' && (
              <div>
                <div className="field-row field-row-2">
                  <div className="field"><label>Código</label><input value={form.codigo} onChange={e=>setF('codigo',e.target.value)} placeholder="001"/></div>
                  <div className="field"><label>Status da empresa</label>
                    <select value={form.status} onChange={e=>setF('status',e.target.value)}>
                      <option>Ativa</option>
                      <option value="Distrato">Saída do escritório (distrato)</option>
                      <option>Baixada</option>
                    </select>
                  </div>
                </div>
                <div className="field"><label>Razão social *</label><input value={form.nome} onChange={e=>setF('nome',e.target.value)} placeholder="Nome completo da empresa"/></div>
                <div className="field-row field-row-2">
                  <div className="field"><label>CNPJ</label><input value={form.cnpj} onChange={e=>setF('cnpj',e.target.value)} placeholder="00.000.000/0001-00"/></div>
                  <div className="field"><label>Inscrição Estadual / CFDF</label><input value={form.cfdf} onChange={e=>setF('cfdf',e.target.value)}/></div>
                </div>
                <div className="field-row field-row-3">
                  <div className="field"><label>UF</label><input value={form.uf} onChange={e=>setF('uf',e.target.value)} placeholder="DF"/></div>
                  <div className="field"><label>Atividade</label><input value={form.atividade} onChange={e=>setF('atividade',e.target.value)} placeholder="Ex: Comércio"/></div>
                  <div className="field"><label>Movimentação</label>
                    <select value={form.movimentacao} onChange={e=>setF('movimentacao',e.target.value)}>
                      <option value="M">M — com movimentação</option>
                      <option value="SM">SM — sem movimentação</option>
                    </select>
                  </div>
                </div>
                <div className="field-row field-row-2">
                  <div className="field"><label>Data de entrada</label><input type="date" value={form.data_entrada} onChange={e=>setF('data_entrada',e.target.value)}/></div>
                  <div className="field"><label>Data de saída / distrato</label><input type="date" value={form.data_saida} onChange={e=>setF('data_saida',e.target.value)}/></div>
                </div>
                <div className="field"><label>Observação de saída / baixa</label><textarea value={form.obs_saida} onChange={e=>setF('obs_saida',e.target.value)} placeholder="Descreva o motivo da saída ou baixa..."/></div>
              </div>
            )}

            {/* TAB TRIBUTARIO */}
            {tab === 'tributario' && (
              <div>
                <div className="field-row field-row-2">
                  <div className="field"><label>Regime tributário</label>
                    <select value={form.grupo_id} onChange={e=>{
                      const g = grupos.find(x=>x.id===e.target.value)
                      setF('grupo_id',e.target.value)
                      if(g) setF('regime_nome',g.nome)
                    }}>
                      <option value="">— selecione —</option>
                      {grupos.map(g=><option key={g.id} value={g.id}>{g.nome}</option>)}
                    </select>
                  </div>
                  <div className="field"><label>Nível de complexidade (peso)</label>
                    <select value={form.peso} onChange={e=>setF('peso',e.target.value)}>
                      <option value="">—</option>
                      <option value="1">1 — simples</option>
                      <option value="2">2 — médio</option>
                      <option value="3">3 — complexo</option>
                      <option value="Não se aplica">Não se aplica</option>
                    </select>
                  </div>
                </div>
                <div className="field-row field-row-2">
                  <div className="field"><label>Responsável fiscal</label><select value={form.resp_fiscal} onChange={e=>setF('resp_fiscal',e.target.value)}>{respOpts}</select></div>
                  <div className="field"><label>Responsável folha</label><select value={form.resp_folha} onChange={e=>setF('resp_folha',e.target.value)}>{respOpts}</select></div>
                </div>
                <div className="field-row field-row-2">
                  <div className="field"><label>Responsável contábil</label><select value={form.resp_contabil} onChange={e=>setF('resp_contabil',e.target.value)}>{respOpts}</select></div>
                  <div className="field"><label>Executado contábil por</label><select value={form.resp_exec_contabil} onChange={e=>setF('resp_exec_contabil',e.target.value)}>{respOpts}</select></div>
                </div>
                <div className="field"><label>Nível de documentação contábil</label>
                  <select value={form.nivel_documental} onChange={e=>setF('nivel_documental',e.target.value)}>
                    <option value="">—</option>
                    <option>SIM - INTEGRAÇÃO</option><option>SIM</option>
                    <option>SIM C/ CONTRATO</option><option>SIM - ELTON</option><option>NÃO SE APLICA</option>
                  </select>
                </div>
                <div className="field-row field-row-2">
                  <div className="field"><label>Fator "R"</label>
                    <select value={form.fator_r?'sim':''} onChange={e=>setF('fator_r',e.target.value==='sim')}>
                      <option value="">Não se aplica</option><option value="sim">Sim — sujeito ao Fator R</option>
                    </select>
                  </div>
                  <div className="field"><label>Retenções</label>
                    <select value={form.retencoes?'sim':''} onChange={e=>setF('retencoes',e.target.value==='sim')}>
                      <option value="">Não</option><option value="sim">Sim</option>
                    </select>
                  </div>
                </div>
              </div>
            )}

            {/* TAB SÓCIOS */}
            {tab === 'socios' && (
              <div>
                <div className="section-label">Quadro societário</div>
                {socios.map((s, i) => (
                  <div className="socio-card" key={s.id || i}>
                    <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:10}}>
                      <span style={{fontWeight:500, fontSize:13}}>Sócio {i+1}</span>
                      <button className="btn btn-sm btn-danger" onClick={()=>removeSocio(i)}><Trash2 size={13}/></button>
                    </div>
                    <div className="field-row field-row-2">
                      <div className="field"><label>Nome completo</label><input value={s.nome||''} onChange={e=>updateSocio(i,'nome',e.target.value)} placeholder="Nome"/></div>
                      <div className="field"><label>CPF</label><input value={s.cpf||''} onChange={e=>updateSocio(i,'cpf',e.target.value)} placeholder="000.000.000-00"/></div>
                    </div>
                    <div className="field-row field-row-3">
                      <div className="field"><label>% participação</label><input type="number" value={s.percentual_participacao||''} onChange={e=>updateSocio(i,'percentual_participacao',e.target.value)} placeholder="0"/></div>
                      <div className="field"><label>Pró-labore (R$)</label><input type="number" value={s.prolabore||''} onChange={e=>updateSocio(i,'prolabore',e.target.value)} placeholder="0,00"/></div>
                      <div className="field"><label>Distribuição de lucros (R$)</label><input type="number" value={s.distribuicao_lucros||''} onChange={e=>updateSocio(i,'distribuicao_lucros',e.target.value)} placeholder="0,00"/></div>
                    </div>
                  </div>
                ))}
                <button className="btn" onClick={addSocio}><Plus size={14}/> Adicionar sócio</button>
              </div>
            )}

            {/* TAB ECD/ECF */}
            {tab === 'ecd_ecf' && (
              <div>
                {['ECD','ECF'].map(tipo => (
                  <div key={tipo}>
                    <div className="section-label">{tipo} — {tipo==='ECD'?'Escrituração Contábil Digital':'Escrituração Contábil Fiscal'}</div>
                    {ANOS.map(ano => {
                      const ob = obrigacoes[`${tipo}-${ano}`]
                      return (
                        <div className="obrig-row" key={ano}>
                          <span className="obrig-ano">{ano}</span>
                          <label className="obrig-check">
                            <input type="checkbox" checked={ob?.transmitida || false} onChange={e=>toggleObrig(tipo,ano,e.target.checked)}/>
                            Transmitida
                          </label>
                          {ob?.transmitida && (
                            <button className="btn btn-sm" onClick={()=>setRecibo(tipo,ano)}>
                              {ob?.numero_recibo ? `Recibo: ${ob.numero_recibo}` : 'Anexar recibo'}
                            </button>
                          )}
                          {ob?.numero_recibo && <span style={{fontSize:12, color:'var(--blue)'}}>{ob.numero_recibo}</span>}
                        </div>
                      )
                    })}
                  </div>
                ))}
                <p style={{fontSize:12, color:'var(--text-faint)', marginTop:16}}>
                  ECD e ECF são obrigatórias para Lucro Real e Lucro Presumido. Marque como transmitida e registre o número do recibo.
                </p>
              </div>
            )}

            {/* TAB HISTÓRICO */}
            {tab === 'historico' && (
              <div>
                <div className="section-label">Registrar ocorrência</div>
                <div className="field"><textarea value={novaObs} onChange={e=>setNovaObs(e.target.value)} placeholder="Descreva a ocorrência, acordo, pendência..."/></div>
                <button className="btn btn-primary btn-sm" onClick={addObs}><Plus size={13}/> Registrar</button>

                <div className="section-label" style={{marginTop:24}}>Histórico</div>
                {historico.length === 0 ? (
                  <p style={{fontSize:13, color:'var(--text-muted)'}}>Nenhuma ocorrência registrada.</p>
                ) : historico.map(h => (
                  <div key={h.id} style={{padding:'10px 14px', background:'var(--bg)', border:'1px solid var(--border)', borderRadius:'var(--radius)', marginBottom:8}}>
                    <div style={{fontSize:11, color:'var(--text-faint)', marginBottom:4}}>
                      {new Date(h.created_at).toLocaleDateString('pt-BR', {day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit'})}
                      {h.usuarios?.nome && ` · ${h.usuarios.nome}`}
                    </div>
                    <div style={{fontSize:13}}>{h.descricao}</div>
                  </div>
                ))}
              </div>
            )}

          </div>
        </div>
      </div>
    </>
  )
}
