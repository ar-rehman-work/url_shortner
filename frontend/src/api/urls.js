import axios from 'axios'

const BASE_URL = 'http://127.0.0.1:3000'

export const createShortUrl = async (payload) => {
  try {
    const { data } = await axios.post(`${BASE_URL}/shorten`, payload)
    return data
  } catch (error) {
    console.error('Error creating short URL:', error)
    throw error
  }
}
