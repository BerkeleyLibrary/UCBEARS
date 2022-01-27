import { format as formatDate } from 'date-fns-tz'
import { parseISO } from 'date-fns'

function ensureDate (isoDate) {
  return (isoDate instanceof Date) ? isoDate : parseISO(isoDate)
}

const rawDateFmtISO = 'yyyy-MM-dd'
const dateTimeFmt = 'yyyy-MM-dd h:mm aa'

export default {
  methods: {
    toDateInputValue (date) {
      const d = ensureDate(date)
      return formatDate(d, rawDateFmtISO)
    },
    fromDateInputValue (dateVal) {
      return parseISO(dateVal)
    },
    formatDateTime: function (date) {
      const d = ensureDate(date)
      return formatDate(d, dateTimeFmt)
    }
  }
}
