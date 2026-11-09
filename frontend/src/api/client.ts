import axios from 'axios'

export const api = axios.create({ baseURL: '/api' })

let token: string | null = localStorage.getItem('portside_token')

export function setToken(t: string | null) {
  token = t
  if (t) localStorage.setItem('portside_token', t)
  else localStorage.removeItem('portside_token')
}

export function getToken() {
  return token
}

api.interceptors.request.use((config) => {
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      setToken(null)
      window.location.href = '/login'
    }
    return Promise.reject(err)
  },
)

export function apiErrorMessage(err: unknown): string {
  const anyErr = err as { response?: { data?: { message?: string } } }
  return anyErr?.response?.data?.message ?? 'Something went wrong.'
}
