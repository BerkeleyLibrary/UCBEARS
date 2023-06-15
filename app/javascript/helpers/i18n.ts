import { format as formatDate } from 'date-fns-tz'
import { parseISO, formatISO } from 'date-fns'

function ensureDate(isoDate: Date | string): Date {
  return (isoDate instanceof Date) ? isoDate : parseISO(isoDate)
}

const rawDateFmtISO = 'yyyy-MM-dd'
const dateTimeFmt = 'yyyy-MM-dd h:mm aa'

export default {
  dateToDateInput: (date: string | Date): string => {
    try {
      const d = ensureDate(date)
      return formatDate(d, rawDateFmtISO)
    } catch (e) {
      console.log(e)
      return ''
    }
  },

  dateToISO8601: (date: string | Date): string => {
    try {
      const d = ensureDate(date)
      return formatISO(d)
    } catch (e) {
      console.log(e)
      return ''
    }
  },

  formatDateTime: (date: string | Date): string => {
    try {
      const d = ensureDate(date)
      return formatDate(d, dateTimeFmt)
    } catch (e) {
      console.log(e)
      return ''
    }
  }
}
