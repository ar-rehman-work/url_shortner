import axios from 'axios'

const api = axios.create({ baseURL: 'http://localhost:3000' })

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')

  if (!!token) {
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

export const createShortUrl = async payload => {
  const { data } = await api.post('/shorten', payload)
  return data
}

export const getShortUrls = async params => {
  const { data } = await api.get('/', { params })
  return data
}
