import { createContext, useEffect, useMemo, useState } from 'react'
import {
  getToken,
  getUser,
  setToken,
  setUser,
  removeToken,
  removeUser
} from '../utils/storage'

const AuthContext = createContext(null)

export const AuthProvider = ({ children }) => {
  const [authToken, setAuthToken] = useState(getToken())
  const [authUser, setAuthUser] = useState(getUser())

  const login = ({ token, user }) => {
    setAuthToken(token)
    setAuthUser(user)

    setToken(token)
    setUser(user)
  }

  const logout = () => {
    setAuthToken(null)
    setAuthUser(null)

    removeToken()
    removeUser()
  }

  const value = useMemo(() => ({
    token: authToken,
    user: authUser,
    login,
    logout,
    isAuthenticated: !!authToken
  }), [authToken, authUser])

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export default AuthContext
