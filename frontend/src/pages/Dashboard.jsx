import Navbar from '../components/Navbar'
import UrlsContent from '../components/UrlsContent'

const Dashboard = () => {
  return (
    <div className='min-h-screen bg-gray-100'>

      <Navbar />

      <div className='max-w-3xl mx-auto p-6 space-y-6'>

        <UrlsContent />

      </div>
    </div>
  )
}

export default Dashboard
