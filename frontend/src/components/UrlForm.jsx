import { useMemo, useState } from 'react'
import { createShortUrl } from '../api/urls'

const UrlForm = ({ onSuccess }) => {
  const [url, setUrl] = useState('')
  const [customAlias, setCustomAlias] = useState('')
  const [expiresAt, setExpiresAt] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const baseUrl = 'http://localhost:3000'

  const previewUrl = useMemo(() => {
    const slug = customAlias?.trim()
    return slug
      ? `${baseUrl}/${slug}`
      : `${baseUrl}/xxxxx`
  }, [customAlias, url])

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!url) return

    setLoading(true)
    setError('')

    try {
      const payload = {
        long_url: url,
        custom_alias: customAlias || undefined,
        expires_at: expiresAt || undefined
      }

      const data = await createShortUrl(payload)

      onSuccess(data)

      setUrl('')
      setCustomAlias('')
      setExpiresAt('')
    } catch (error) {
      setError('URL shortening failed. Please enter valid data.')
    }

    setLoading(false)
  }

  return (
    <div className='bg-white border border-gray-200 rounded-2xl shadow-sm p-6 space-y-5'>

      <div>
        <h2 className='text-lg font-semibold text-gray-800'>
          Shorten a long URL
        </h2>
        <p className='text-sm text-gray-500'>
          Customize your link and set expiration if needed
        </p>
      </div>

      <form onSubmit={handleSubmit} className='space-y-4'>

        <input
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder='https://example.com/very/long/url'
          className='w-full border border-gray-300 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-1 focus:ring-black'
        />

        <input
          value={customAlias}
          onChange={(e) => setCustomAlias(e.target.value)}
          placeholder='custom-alias (optional)'
          className='w-full border border-gray-300 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-1 focus:ring-black'
        />

        <input
          type='datetime-local'
          value={expiresAt}
          onChange={(e) => setExpiresAt(e.target.value)}
          className='w-full border border-gray-300 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-1 focus:ring-black'
        />

        <div className='bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm'>
          <p className='text-xs text-gray-500 mb-1'>Preview</p>
          <p className='font-mono text-black break-all'>
            {previewUrl}
          </p>
        </div>

        <button
          disabled={loading}
          className='w-full bg-black text-white py-3 rounded-xl font-medium hover:bg-gray-900 transition disabled:opacity-50'
        >
          {loading ? 'Shortening...' : 'Generate short link'}
        </button>

      </form>

      {error && (
        <div className='bg-red-50 border border-red-200 text-red-600 text-sm px-4 py-2 rounded-lg'>
          {error}
        </div>
      )}

    </div>
  )
}

export default UrlForm
