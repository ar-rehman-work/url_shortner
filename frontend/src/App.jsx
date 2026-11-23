import { Routes, Route } from 'react-router-dom'

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
