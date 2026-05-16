import { Routes, Route } from 'react-router-dom'

import Login from './pages/Login'
import Signup from './pages/Signup'
import Dashboard from './pages/Dashboard'

import { appRoutes } from './routes/appRoutes'

const App = () => {
  return (
    <Routes>
      {appRoutes.map(({ path, element }) => (
        <Route
          key={path}
          path={path}
          element={element}
        />
      ))}
    </Routes>
  )
}

export default App
