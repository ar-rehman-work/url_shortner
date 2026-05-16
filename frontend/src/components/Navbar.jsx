import { useNavigate } from 'react-router-dom'
import useAuth from '../hooks/useAuth'

const Navbar = () => {
  const navigate = useNavigate()
  const { user, logout } = useAuth()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const initial = user?.name?.charAt(0)?.toUpperCase()

  return (
    <header className='sticky top-0 z-50 bg-white/80 backdrop-blur border-b border-gray-200'>
      <div className='max-w-4xl mx-auto px-4 py-3 flex items-center justify-between'>

        <h1 className='text-lg font-bold text-gray-900 tracking-tight'>
          URL Shortener
        </h1>

        <div className='flex items-center gap-3'>

          <div className='flex items-center gap-2 bg-gray-100 px-3 py-1.5 rounded-full'>
            <div className='w-7 h-7 flex items-center justify-center rounded-full bg-black text-white text-xs font-semibold'>
              {initial}
            </div>

            <span className='text-sm text-gray-700 font-medium'>
              {user?.name}
            </span>
          </div>

          <button
            onClick={handleLogout}
            className='text-sm px-3 py-1.5 rounded-full border border-gray-300 text-gray-700 hover:bg-gray-900 hover:text-white transition'
          >
            Logout
          </button>

        </div>
      </div>
    </header>
  )
}

export default Navbar
