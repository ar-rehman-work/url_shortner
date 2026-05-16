import { Navigate } from 'react-router-dom'

import RouteHandler from '../components/RouteHandler'
import Dashboard from '../pages/Dashboard'
import Login from '../pages/Login'
import Signup from '../pages/Signup'
import Home from '../pages/Home'

export const nonProtectedRoutes = [
  {
    path: '/',
    element: <Home />
  }
]

export const protectedRoutes = [
  {
    path: '/dashboard',
    element: <Dashboard />
  }
]

export const mustNotProtectedRoutes = [
  {
    path: '/login',
    element: <Login />
  },
  {
    path: '/signup',
    element: <Signup />
  }
]

const buildRoutes = (routes, routeHandlerProps = {}) => {
  return routes.map(({ element, ...route }) => ({
    ...route,
    element: (
      <RouteHandler {...routeHandlerProps}>
        {element}
      </RouteHandler>
    )
  }))
}

export const appRoutes = [
  ...buildRoutes(nonProtectedRoutes),
  ...buildRoutes(protectedRoutes, { isProtected: true }),
  ...buildRoutes(mustNotProtectedRoutes, { mustNotBeProtected: true })
]
