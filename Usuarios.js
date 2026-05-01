import React, { useState, useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { supabase } from './lib/supabase'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Clientes from './pages/Clientes'
import ClienteFicha from './pages/ClienteFicha'
import { Usuarios, Competencias, Grupos } from './pages/Usuarios'
import Layout from './components/Layout'
import './App.css'

export default function App() {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session); setLoading(false)
    })
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, s) => setSession(s))
    return () => subscription.unsubscribe()
  }, [])

  if (loading) return (
    <div className="loading-screen">
      <div className="loading-logo">RF</div>
      <p style={{fontSize:13,color:'#888',marginTop:8}}>Carregando...</p>
    </div>
  )

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={!session ? <Login /> : <Navigate to="/" />} />
        <Route path="/" element={session ? <Layout session={session} /> : <Navigate to="/login" />}>
          <Route index element={<Dashboard />} />
          <Route path="clientes" element={<Clientes />} />
          <Route path="clientes/novo" element={<ClienteFicha />} />
          <Route path="clientes/:id" element={<ClienteFicha />} />
          <Route path="usuarios" element={<Usuarios />} />
          <Route path="competencias" element={<Competencias />} />
          <Route path="grupos" element={<Grupos />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
