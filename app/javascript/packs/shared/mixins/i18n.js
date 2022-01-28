import { format as formatDate } from 'date-fns-tz'
import { parseISO, formatISO } from 'date-fns'

function ensureDate (isoDate) {
  return (isoDate instanceof Date) ? isoDate : parseISO(isoDate)
}

const rawDateFmtISO = 'yyyy-MM-dd'
const dateTimeFmt = 'yyyy-MM-dd h:mm aa'

export default {
  methods: {
    dateToDateInput (date) {
      try {
        const d = ensureDate(date)
        return formatDate(d, rawDateFmtISO)
      } catch (e) {
        console.log(e)
        return null
      }
    },
    dateToISO8601 (dateVal) {
      try {
        const d = ensureDate(dateVal)
        return formatISO(d)
      } catch (e) {
        console.log(e)
        return null
      }
    },
    formatDateTime: function (date) {
      try {
        const d = ensureDate(date)
        return formatDate(d, dateTimeFmt)
      } catch (e) {
        console.log(e)
        return null
      }
    }
  }
}
