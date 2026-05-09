import { useState } from 'react'
import { createShortUrl } from '../api/urls'

const UrlForm = ({ onSuccess }) => {
  const [url, setUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!url) return

    setLoading(true)
    setError('')

    try {
      const data = await createShortUrl({ long_url: url })

      onSuccess(data)
      setUrl('')
    } catch (error) {
      setError(
        error.response?.data?.error || 'Failed to shorten URL'
      )
    }

    setLoading(false)
  }

  return (
    <div className="bg-white border border-gray-200 rounded-2xl shadow-sm p-6">

      <div className="mb-4">
        <h2 className="text-lg font-semibold text-gray-800">
          Shorten a long URL
        </h2>
        <p className="text-sm text-gray-500">
          Paste your link and get a short shareable URL instantly.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-3">

        <div>
          <input
            value={url}
            onChange={e => setUrl(e.target.value)}
            placeholder="https://example.com/very/long/url"
            className="w-full border border-gray-300 rounded-xl px-4 py-3 text-sm text-gray-800 focus:outline-none focus:ring-1 focus:ring-black focus:border-black transition"
          />
        </div>

        <button
          disabled={loading}
          className="w-full bg-black text-white py-3 rounded-xl font-medium hover:bg-gray-900 transition disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loading ? 'Shortening...' : 'Generate short link'}
        </button>

      </form>

      {error && (
        <div className="mt-4 bg-red-50 border border-red-200 text-red-600 text-sm px-4 py-2 rounded-lg">
          {error}
        </div>
      )}

    </div>
  )
}

export default UrlForm
