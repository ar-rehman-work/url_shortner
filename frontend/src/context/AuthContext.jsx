import { createContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'

const AuthContext = createContext()

export const AuthProvider = ({ children }) => {
  const [token, setToken] = useState(null)
  const [user, setUser] = useState(null)

  useEffect(() => {
    const storedToken = localStorage.getItem('token')
    const storedUser = localStorage.getItem('user')

    if (!!storedToken) {
      setToken(storedToken)
    }

    if (!!storedUser) {
      setUser(JSON.parse(storedUser))
    }
  }, [])

  const login = ({ token, user }) => {
    localStorage.setItem('token', token)
    localStorage.setItem('user', JSON.stringify(user))

    setToken(token)
    setUser(user)
  }

  const logout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')

    setToken(null)
    setUser(null)
  }

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        login,
        logout,
        isAuthenticated: !!token
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export default AuthContext
