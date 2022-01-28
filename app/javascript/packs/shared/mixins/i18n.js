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
      const d = ensureDate(date)
      return formatDate(d, rawDateFmtISO)
    },
    dateToISO8601 (dateVal) {
      const d = ensureDate(dateVal)
      return formatISO(d)
    },
    formatDateTime: function (date) {
      const d = ensureDate(date)
      return formatDate(d, dateTimeFmt)
    }
  }
}
