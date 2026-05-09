import { useState } from 'react'

import Navbar from '../components/Navbar'
import UrlForm from '../components/UrlForm'
import UrlCard from '../components/UrlCard'

const Dashboard = () => {
  const [shortUrls, setShortUrls] = useState([])

  const addShortUrl = (data) => {
    setShortUrls(prev => [data, ...prev])
  }

  return (
    <div className="min-h-screen bg-gray-100">

      <Navbar />

      <div className="max-w-3xl mx-auto p-6 space-y-6">

        <UrlForm onSuccess={addShortUrl} />

        <div className="space-y-4">
          {shortUrls.map(item => (
            <UrlCard
              key={item.short_code}
              shortUrl={item}
            />
          ))}
        </div>

      </div>
    </div>
  )
}

export default Dashboard
