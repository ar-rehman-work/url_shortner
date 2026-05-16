import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'

import { getShortUrls } from '../api/urls'

import UrlForm from './UrlForm'
import UrlList from './UrlList'
import UrlCard from './UrlCard'

const UrlsContent = () => {
  const [shortUrls, setShortUrls] = useState([])
  const [shortUrl, setShortUrl] = useState()
  const [searchParams, setSearchParams] = useSearchParams()

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

  const onFilterChange = (key, value) => {
    const params = new URLSearchParams(searchParams)

    if (!value) params.delete(key)
    else params.set(key, value)

    setSearchParams(params)
  }

  return (
    <div className='space-y-4'>
      <UrlForm onSuccess={addShortUrl} />

      { shortUrl && <UrlCard shortUrl={shortUrl} /> }

      <UrlList
        urls={shortUrls}
        filters={query}
        onFilterChange={onFilterChange}
        searchParams={searchParams}
        setSearchParams={setSearchParams}
      />

    </div>
  )
}

export default UrlsContent
