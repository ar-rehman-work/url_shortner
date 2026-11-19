import { useState } from 'react'
import { Copy, Pencil } from 'lucide-react'

const UrlItem = ({ url, onEdit }) => {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(url.short_url)

    setCopied(true)
    setTimeout(() => setCopied(false), 1200)
  }

  return (
    <div className={`grid grid-cols-12 px-5 py-4 items-center hover:bg-gray-50 transition ${
      url.active ? 'hover:bg-gray-50' : 'opacity-50 cursor-not-allowed pointer-events-none'}`}>

      <div className='col-span-5 text-sm text-gray-800 truncate pr-3'>
        {url.long_url.length > 60
          ? url.long_url.slice(0, 60) + '...'
          : url.long_url}
      </div>

      <div className='col-span-4 text-sm'>
        {url.short_url ? (
          <a
            href={url.short_url}
            target='_blank'
            rel='noreferrer'
            className='text-black hover:underline'
          >
            {url.short_url}
          </a>
        ) : (
          <span className='text-red-500 text-xs font-medium'>
            URL unavailable
          </span>
        )}
      </div>

      <div className='col-span-2 flex flex-wrap items-center gap-2'>
        <span
          className={`px-3 py-1 text-xs font-medium border rounded-full ${
            !url.active
              ? 'bg-gray-50 text-gray-500 border-gray-200'
              : url.expired
                ? 'bg-red-50 text-red-600 border-red-100'
                : 'bg-green-50 text-green-600 border-green-100'
          }`}
        >
          {!url.active ? 'Inactive' : url.expired ? 'Expired' : 'Active'}
        </span>

        {url.custom && (
          <span className='px-3 py-1 text-xs font-medium bg-orange-50 text-orange-600 border border-orange-100 rounded-full'>
            Custom
          </span>
        )}
      </div>

      <div className='col-span-1 flex justify-end gap-2'>
        <button
          type='button'
          onClick={() => onEdit(url)}
          className='p-2 rounded-lg hover:bg-gray-100 transition'
          title='Edit URL'
        >
          <Pencil size={16} className='text-gray-600' />
        </button>

        <button
          type='button'
          onClick={handleCopy}
          className='p-2 rounded-lg hover:bg-gray-100 transition relative'
          title='Copy URL'
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
