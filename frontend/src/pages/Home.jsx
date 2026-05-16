import { Link } from 'react-router-dom'

const Home = () => {
  return (
    <main className='min-h-screen bg-gray-50'>
      <section className='mx-auto flex min-h-screen max-w-6xl flex-col items-center justify-center px-6 text-center'>
        <h1 className='mb-6 text-4xl font-bold text-gray-900 md:text-6xl'>
          Shorten URLs.
          <br />
          Track links faster.
        </h1>

        <p className='mb-8 max-w-2xl text-lg text-gray-600'>
          Create short, clean, and manageable links with authentication,
          custom aliases, expiry support, and a simple dashboard.
        </p>

        <div className='flex flex-col gap-4 sm:flex-row'>
          <Link
            to='/dashboard'
            className='rounded-lg bg-blue-600 px-6 py-3 font-medium text-white transition hover:bg-blue-700'
          >
            Get Started
          </Link>

          <Link
            to='/login'
            className='rounded-lg border border-gray-300 px-6 py-3 font-medium text-gray-700 transition hover:bg-gray-100'
          >
            Login
          </Link>
        </div>

        <div className='mt-16 grid w-full gap-6 md:grid-cols-3'>
          <div className='rounded-xl bg-white p-6 shadow-sm'>
            <h3 className='mb-2 text-xl font-semibold text-gray-900'>
              Short Links
            </h3>
            <p className='text-gray-600'>
              Convert long URLs into clean and shareable short links.
            </p>
          </div>

          <div className='rounded-xl bg-white p-6 shadow-sm'>
            <h3 className='mb-2 text-xl font-semibold text-gray-900'>
              Custom Alias
            </h3>
            <p className='text-gray-600'>
              Create meaningful short URLs using your own custom path.
            </p>
          </div>

          <div className='rounded-xl bg-white p-6 shadow-sm'>
            <h3 className='mb-2 text-xl font-semibold text-gray-900'>
              Expiry Support
            </h3>
            <p className='text-gray-600'>
              Set expiration dates and automatically disable old links.
            </p>
          </div>
        </div>
      </section>
    </main>
  )
}

export default Home
