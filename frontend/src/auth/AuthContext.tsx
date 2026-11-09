import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { AuthApi } from '../api/resources'
import { getToken, setToken } from '../api/client'
import type { LoginResponse, Role } from '../api/types'

interface AuthState {
  user: LoginResponse | null
  loading: boolean
  login: (username: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<LoginResponse | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (getToken()) {
      AuthApi.me()
        .then((me) => setUser({ ...me, token: getToken() }))
        .catch(() => setToken(null))
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  async function login(username: string, password: string) {
    const res = await AuthApi.login(username, password)
    setToken(res.token)
    setUser(res)
  }

  function logout() {
    setToken(null)
    setUser(null)
  }

  return <AuthContext.Provider value={{ user, loading, login, logout }}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

export function hasRole(role: Role | undefined, ...allowed: Role[]) {
  return !!role && allowed.includes(role)
}
