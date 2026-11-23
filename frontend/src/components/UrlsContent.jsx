import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

import { getShortUrls } from '../api/urls'

import UrlForm from './UrlForm'
import UrlList from './UrlList'
import UrlCard from './UrlCard'

const UrlsContent = () => {
  const [shortUrls, setShortUrls] = useState([])
  const [shortUrl, setShortUrl] = useState()
  const [editingUrl, setEditingUrl] = useState(null)
  const [searchParams, setSearchParams] = useSearchParams()
  const [isUrlModalOpen, setIsUrlModalOpen] = useState(false)

  const query = useMemo(() => {
    return Object.fromEntries([...searchParams])
  }, [searchParams])

  useEffect(() => {
    const fetchData = async () => {
      try {
        const data = await getShortUrls(query)

        setShortUrls(data.data || [])
      } catch (error) {
        console.error(error)
      }
    }

    fetchData()
  }, [query])

  const addShortUrl = (data) => {
    setShortUrls((prev) => [data, ...prev])
    setShortUrl(data)
  }

  const updateShortUrl = (data) => {
    setShortUrls((prev) =>
      prev.map((url) => url.id === data.id ? data : url)
    )
    setShortUrl(data)
  }

  const onFilterChange = (key, value) => {
    const params = new URLSearchParams(searchParams)

    if (!value) params.delete(key)
    else params.set(key, value)

    setSearchParams(params)
  }

  return (
    <div className='space-y-4'>
     <div className='flex justify-end'>
        <button
          type='button'
          onClick={() => setIsUrlModalOpen(true)}
          className='bg-black text-white px-4 py-2 rounded-xl hover:bg-gray-900 transition'
        >
          + New
        </button>
      </div>

      {(isUrlModalOpen || Boolean(editingUrl)) && (
        <UrlForm
          key={editingUrl ? `edit-${editingUrl.id}` : 'new'}
          onClose={() => {
            setIsUrlModalOpen(false)
            setEditingUrl(null)
          }}
          onSuccess={editingUrl ? updateShortUrl : addShortUrl}
          shortUrl={editingUrl}
        />
      )}

      { shortUrl && <UrlCard shortUrl={shortUrl} /> }

      <UrlList
        urls={shortUrls}
        filters={query}
        onFilterChange={onFilterChange}
        searchParams={searchParams}
        setSearchParams={setSearchParams}
        onEdit={(url) => setEditingUrl(url)}
      />

    </div>
  )
}

export default UrlsContent
