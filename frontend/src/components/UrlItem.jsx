import { useState } from 'react'
import { Copy } from 'lucide-react'

const UrlItem = ({ url }) => {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(url.short_url)

    setCopied(true)
    setTimeout(() => setCopied(false), 1200)
  }

  return (
    <div className='grid grid-cols-12 px-5 py-4 items-center hover:bg-gray-50 transition'>

      <div className='col-span-5 text-sm text-gray-800 truncate pr-3'>
        {url.long_url.length > 60
          ? url.long_url.slice(0, 60) + '...'
          : url.long_url}
      </div>

      <div className='col-span-3 text-sm'>
        <a
          href={url.short_url}
          target='_blank'
          rel='noreferrer'
          className='text-black hover:underline'
        >
          {url.short_url}
        </a>
      </div>

      <div className='col-span-2'>
        {url.expired ? (
          <span className='px-3 py-1 text-xs bg-red-50 text-red-600 border border-red-100 rounded-full'>
            Expired
          </span>
        ) : (
          <span className='px-3 py-1 text-xs bg-green-50 text-green-600 border border-green-100 rounded-full'>
            Active
          </span>
        )}
        {url.custom && (
          <span className='px-3 py-1 text-xs bg-orange-50 text-orange-600 border border-orange-100 rounded-full'>
            Custom
          </span>
        )}
      </div>

      <div className='col-span-2 flex justify-end'>
        <button
          onClick={handleCopy}
          className='p-2 rounded-lg hover:bg-gray-100 transition relative'
        >
          <Copy size={16} className='text-gray-600' />

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

export default UrlItem
