import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'

import { loginUser } from '../api/urls'
import useAuth from '../hooks/useAuth'

const Login = () => {
  const navigate = useNavigate()
  const { login } = useAuth()

  const [formData, setFormData] = useState({
    email: '',
    password: ''
  })

  const [error, setError] = useState('')

  const handleChange = event => {
    setFormData({
      ...formData,
      [event.target.name]: event.target.value
    })
  }

  const handleSubmit = async event => {
    event.preventDefault()
    setError('')

    try {
      const data = await loginUser(formData)

      login(data)
      navigate('/dashboard')
    } catch (error) {
      setError(
        error.response?.data?.error ||
        'Login failed'
      )
    }
  }

  return (
    <div className="h-screen flex items-center justify-center bg-gray-100">
      <div className="w-full max-w-md bg-white p-8 rounded-2xl shadow-lg">
        
        <h2 className="text-3xl font-bold text-center text-gray-800 mb-6">
          Welcome Back
        </h2>

        {error && (
          <div className="bg-red-50 text-red-600 text-sm p-3 rounded mb-4 border border-red-200">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">

          <input
            name="email"
            placeholder="Email"
            className="w-full border border-gray-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-black"
            onChange={handleChange}
          />

          <input
            name="password"
            type="password"
            placeholder="Password"
            className="w-full border border-gray-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-black"
            onChange={handleChange}
          />

          <button
            type="submit"
            className="w-full bg-black text-white py-3 rounded-lg font-semibold hover:bg-gray-800 transition"
          >
            Login
          </button>

        </form>

        <p className="text-sm text-center mt-6 text-gray-600">
          No account?{' '}
          <Link to="/signup" className="text-black font-medium hover:underline">
            Signup
          </Link>
        </p>

      </div>
    </div>
  )
}

export default Login
