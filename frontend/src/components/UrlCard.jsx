import { useState } from 'react'
import { Copy } from 'lucide-react'

const UrlCard = ({ shortUrl }) => {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(shortUrl.short_url)

    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <div className='bg-white border border-gray-200 rounded-xl p-5 shadow-sm hover:shadow-md transition'>

      <div className='flex items-center justify-between gap-3'>

        <div className='min-w-0'>
          <p className='text-xs text-gray-500 uppercase tracking-wide mb-1'>
            Short URL
          </p>

          <a
            href={shortUrl.short_url}
            target='_blank'
            rel='noreferrer'
            className='text-blue-600 hover:text-blue-700 font-mono text-sm break-all'
          >
            {shortUrl.short_url}
          </a>
        </div>

        <button
          onClick={handleCopy}
          className='p-2 rounded-lg hover:bg-gray-100 transition relative'
        >
          <Copy size={18} className='text-gray-700' />

          {copied && (
            <span className='absolute -top-6 right-0 text-xs bg-black text-white px-2 py-1 rounded'>
              Copied
            </span>
          )}
        </button>

      </div>
    </div>
  )
}

export default UrlCard
