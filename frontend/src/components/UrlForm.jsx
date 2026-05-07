import { useState } from 'react'
import { createShortUrl } from '../api/urls'

const UrlForm = () => {
  const [url, setUrl] = useState('')
  const [shortCode, setShortCode] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!url) return

    setLoading(true)

    try {
      const data = await createShortUrl({ long_url: url })
      setShortCode(data.short_code)
    } catch (err) {
      console.log(err)
    }

    setLoading(false)
  }

  return (
    <div className='min-h-screen flex items-center justify-center bg-gray-100 p-4'>
      <div className='w-full max-w-md bg-white rounded-2xl shadow-lg p-6'>
        
        <h1 className='text-2xl font-bold text-gray-800 mb-6 text-center'>
          URL Shortener
        </h1>

        <form onSubmit={handleSubmit} className='space-y-4'>
          
          <input
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder='Enter long URL...'
            className='w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500'
          />

          <button
            type='submit'
            disabled={loading}
            className='w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-3 rounded-lg transition'
          >
            {loading ? 'Shortening...' : 'Shorten URL'}
          </button>
        </form>

        {shortCode && (
          <div className='mt-6 p-4 bg-gray-50 rounded-lg text-center'>
            <p className='text-sm text-gray-600 mb-2'>Your short URL</p>

            <a
              href={`http://localhost:3000/${shortCode}`}
              target='_blank'
              className='text-blue-600 font-medium break-all'
            >
              {`http://localhost:3000/${shortCode}`}
            </a>
          </div>
        )}

      </div>
    </div>
  )
}

export default UrlForm