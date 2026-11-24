import { useMemo, useState } from 'react'
import { shortenUrl, BACKEND_URL } from '../api/urls'

const UrlForm = ({ onClose, onSuccess, shortUrl }) => {
  const [url, setUrl] = useState(() => shortUrl?.long_url || '')
  const [customAlias, setCustomAlias] = useState(() => shortUrl?.custom ? shortUrl.slug || '' : '')
  const [expiresAt, setExpiresAt] = useState(() =>
    shortUrl?.expires_at
      ? new Date(
          new Date(shortUrl.expires_at).getTime() -
          new Date(shortUrl.expires_at).getTimezoneOffset() * 60000
        ).toISOString().slice(0, 16)
      : ''
  )
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const isEditing = Boolean(shortUrl)

  const previewUrl = useMemo(() => {
    const slug = customAlias.trim() || shortUrl?.slug

    return slug
      ? `${BACKEND_URL}/${slug}`
      : `${BACKEND_URL}/xxxxx`
  }, [customAlias, shortUrl])

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!url.trim()) return

    setLoading(true)
    setError('')

    try {
      const payload = {
        long_url: url,
        custom_alias: customAlias,
        expires_at: expiresAt || null
      }

      const data = await shortenUrl(payload, shortUrl?.id)

      onSuccess(data)

      if (!isEditing) {
        setUrl('')
        setCustomAlias('')
        setExpiresAt('')
      }

      onClose()
    } catch (error) {
      setError(error.response?.data?.errors?.join(', ') || error.response?.data?.error || 'URL operation failed. Please check your input.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className='fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4'
      onClick={onClose}
    >
      <div
        className='w-full max-w-lg bg-white rounded-2xl shadow-xl p-6 space-y-5'
        onClick={(e) => e.stopPropagation()}
      >
        <div className='flex items-center justify-between'>
          <div>
            <h2 className='text-lg font-semibold text-gray-800'>
              {isEditing ? 'Edit short URL' : 'Shorten a long URL'}
            </h2>
            <p className='text-sm text-gray-500'>
              Customize your link and set expiration if needed
            </p>
          </div>

          <button
            type='button'
            onClick={onClose}
            className='text-gray-500 hover:text-black text-xl'
          >
            ×
          </button>
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

          {error && (
            <div className='bg-red-50 border border-red-200 text-red-600 text-sm px-4 py-2 rounded-lg'>
              {error}
            </div>
          )}

          <button
            disabled={loading}
            className='w-full bg-black text-white py-3 rounded-xl font-medium hover:bg-gray-900 transition disabled:opacity-50'
          >
            {loading
              ? isEditing ? 'Updating...' : 'Shortening...'
              : isEditing ? 'Update short link' : 'Generate short link'}
          </button>
        </form>
      </div>
    </div>
  )
}

export default UrlForm
