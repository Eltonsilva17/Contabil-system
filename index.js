import React, { useState, useEffect } from 'react'
import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import {
  LayoutDashboard, Users, Building2, CalendarDays,
  Tags, LogOut, ChevronRight
} from 'lucide-react'

export default function Layout({ session }) {
  const navigate = useNavigate()
  const [escritorio, setEscritorioNome] = useState('Escritório')
  const [usuario, setUsuario] = useState(null)

  useEffect(() => {
    async function load() {
      const { data: u } = await supabase
        .from('usuarios')
        .select('nome, nivel, escritorio_id, escritorios(nome)')
        .eq('id', session.user.id)
        .single()
      if (u) {
        setUsuario(u)
        setEscritorioNome(u.escritorios?.nome || 'Escritório')
      }
    }
    load()
  }, [session])

  async function handleLogout() {
    await supabase.auth.signOut()
    navigate('/login')
  }

  const initials = usuario?.nome
    ? usuario.nome.split(' ').slice(0,2).map(n => n[0]).join('').toUpperCase()
    : '??'

  return (
    <div className="app-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-name">{escritorio}</div>
          <div className="sidebar-brand-sub">Sistema Gerencial</div>
        </div>

        <div className="sidebar-section">
          <NavItem to="/" icon={<LayoutDashboard size={15}/>} label="Painel" end />
          <NavItem to="/clientes" icon={<Building2 size={15}/>} label="Clientes" />
        </div>

        <div className="sidebar-section">
          <div className="sidebar-section-label">Configurações</div>
          <NavItem to="/usuarios" icon={<Users size={15}/>} label="Usuários" />
          <NavItem to="/competencias" icon={<CalendarDays size={15}/>} label="Competências" />
          <NavItem to="/grupos" icon={<Tags size={15}/>} label="Grupos / Regimes" />
        </div>

        <div className="sidebar-footer">
          <div className="user-chip">
            <div className="user-avatar">{initials}</div>
            <div>
              <div className="user-name">{usuario?.nome || session.user.email}</div>
              <div className="user-role">{usuario?.nivel || 'usuário'}</div>
            </div>
          </div>
          <button className="nav-link" onClick={handleLogout} style={{marginTop: 4}}>
            <LogOut size={15}/> Sair
          </button>
        </div>
      </aside>

      <main className="main-area">
        <Outlet />
      </main>
    </div>
  )
}

function NavItem({ to, icon, label, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
    >
      {icon}
      {label}
    </NavLink>
  )
}
