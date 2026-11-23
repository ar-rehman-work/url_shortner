import axios from 'axios'

export const BACKEND_URL = import.meta.env.VITE_BACKEND_URL
const API_VERSION = import.meta.env.VITE_API_VERSION
const BACKEND_API_URL = `${BACKEND_URL}/${API_VERSION}`

const api = axios.create({ baseURL: BACKEND_API_URL })

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')

  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

export const signup = async payload => {
  const { data } = await api.post('/signup', payload)
  return data
}

export const loginUser = async payload => {
  const { data } = await api.post('/login', payload)
  return data
}

export const shortenUrl = async (payload, id = null) => {
  const { data } = id
    ? await api.put(`/shorten/${id}`, payload)
    : await api.post('/shorten', payload)

  return data
}

export const getShortUrls = async params => {
  const { data } = await api.get('/', { params })
  return data
}
