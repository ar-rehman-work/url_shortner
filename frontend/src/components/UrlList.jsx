import UrlItem from './UrlItem'

const UrlList = ({
  urls,
  filters,
  onFilterChange
}) => {
  return (
    <div className='space-y-5'>

      <div className='bg-white border border-gray-200 rounded-2xl shadow-sm p-5 space-y-4'>

        <div>
          <h2 className='text-lg font-semibold text-gray-800'>
            Your URLs
          </h2>
          <p className='text-sm text-gray-500'>
            Search and filter your shortened links
          </p>
        </div>

        <div className='flex flex-col md:flex-row gap-3'>

          <input
            value={filters.q || ''}
            placeholder='Search URLs or aliases...'
            onChange={(e) => onFilterChange('q', e.target.value)}
            className='flex-1 border border-gray-300 rounded-xl px-4 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-black focus:border-black'
          />

          <select
            value={filters.expired || ''}
            onChange={(e) => onFilterChange('expired', e.target.value)}
            className='border border-gray-300 rounded-xl px-4 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-black'
          >
            <option value=''>All Status</option>
            <option value='true'>Expired</option>
            <option value='false'>Active</option>
          </select>

          <select
            value={filters.custom || ''}
            onChange={(e) => onFilterChange('custom', e.target.value)}
            className='border border-gray-300 rounded-xl px-4 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-black'
          >
            <option value=''>All Types</option>
            <option value='true'>Custom</option>
            <option value='false'>Generated</option>
          </select>

        </div>

      </div>

      {urls.length === 0 ? (
        <div className='bg-white border border-gray-200 rounded-2xl p-10 text-center text-gray-500'>
          No URL found
        </div>
      ) : (
        <div className='bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden'>

          <div className='grid grid-cols-12 px-5 py-3 text-xs font-semibold text-gray-500 border-b border-gray-200'>
            <div className='col-span-5'>Original URL</div>
            <div className='col-span-3'>Short URL</div>
            <div className='col-span-2'>Status & Type</div>
            <div className='col-span-2 text-right'>Actions</div>
          </div>

          <div className='divide-y divide-gray-100'>
            {urls.map((url) => (
              <UrlItem key={url.id} url={url} />
            ))}
          </div>

          <div className='border-t border-gray-200 px-5 py-4 flex justify-between items-center'>

            <button
              disabled={!filters?.prev}
              onClick={() => onFilterChange((filters?.page || 1) - 1)}
              className='px-4 py-2 text-sm border border-gray-300 rounded-xl hover:bg-gray-50 disabled:opacity-40 transition'
            >
              ← Previous
            </button>

            <span className='text-sm text-gray-500'>
              Page {filters?.page || 1}
            </span>

            <button
              disabled={!filters?.next}
              onClick={() => onFilterChange((filters?.page || 1) + 1)}
              className='px-4 py-2 text-sm border border-gray-300 rounded-xl hover:bg-gray-50 disabled:opacity-40 transition'
            >
              Next →
            </button>

          </div>

        </div>
      )}

    </div>
  )
}

export default UrlList
