import { Navigate, useLocation } from 'react-router-dom'

import useAuth from '../hooks/useAuth'

const DEFAULT_AUTHENTICATED_PATH = '/dashboard'
const DEFAULT_UNAUTHENTICATED_PATH = '/login'

const getRedirectPath = location => {
  const from = location.state?.from

  if (!from) {
    return DEFAULT_AUTHENTICATED_PATH
  }

  return `${from.pathname}${from.search || ''}${from.hash || ''}`
}

const RouteHandler = ({
  children,
  isProtected = false,
  mustNotBeProtected = false,
  authenticatedRedirectTo,
  unauthenticatedRedirectTo = DEFAULT_UNAUTHENTICATED_PATH
}) => {
  const location = useLocation()
  const { isAuthenticated } = useAuth()

  if (isProtected && !isAuthenticated) {
    return (
      <Navigate
        to={unauthenticatedRedirectTo}
        replace
        state={{ from: location }}
      />
    )
  }

  if (mustNotBeProtected && isAuthenticated) {
    return (
      <Navigate
        to={authenticatedRedirectTo || getRedirectPath(location)}
        replace
      />
    )
  }

  return children
}

export default RouteHandler
