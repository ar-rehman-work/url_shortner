import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'

import { signup } from '../api/urls'
import useAuth from '../hooks/useAuth'

const Signup = () => {
  const navigate = useNavigate()

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: ''
  })

  const [errors, setErrors] = useState([])

  const handleChange = event => {
    setFormData({
      ...formData,
      [event.target.name]: event.target.value
    })
  }

  const handleSubmit = async event => {
    event.preventDefault()

    setErrors([])

    try {
      const data = await signup(formData)

      navigate('/login')
    } catch (error) {
      setErrors(
        error.response?.data?.errors || ['Signup failed']
      )
    }
  }

  return (
    <div className="h-screen flex items-center justify-center bg-gray-100">

      <div className="w-full max-w-md bg-white p-8 rounded-2xl shadow-lg">

        <h2 className="text-3xl font-bold text-center text-gray-800 mb-6">
          Create Account
        </h2>

        {errors.length > 0 && (
          <div className="bg-red-50 border border-red-200 text-red-600 text-sm p-3 rounded mb-4">
            <ul className="list-disc ml-5">
              {errors.map((err, index) => (
                <li key={index}>{err}</li>
              ))}
            </ul>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">

          <input
            name="name"
            placeholder="Name"
            className="w-full border border-gray-300 p-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-black"
            onChange={handleChange}
          />

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
            Signup
          </button>

        </form>

        <p className="text-sm text-center mt-6 text-gray-600">
          Already have an account?{' '}
          <Link to="/login" className="text-black font-medium hover:underline">
            Login
          </Link>
        </p>

      </div>
    </div>
  )
}

export default Signup
