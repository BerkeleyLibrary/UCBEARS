import { defineStore } from "pinia";
import { ref, Ref } from 'vue'
import { Term, TermEdit } from "../types/Term";
import { useTermsApi } from "./terms-api";
import { TermFilter } from "../types/TermFilter";

export const useTermsStore = defineStore('terms', () => {
  // --------------------------------------------------
  // Exported fields and functions

  const terms: Ref<Term[]> = ref([])
  const termFilter: Ref<TermFilter> = ref({})

  function saveTerm(term: TermEdit) {
    return doSave(term).then(setTerm)
  }

  function deleteTerm(term: Term) {
    const termsApi = useTermsApi()
    return termsApi.delete(term).then(removeTerm)
  }

  function reloadTerms() {
    const termsApi = useTermsApi()
    return termsApi.findTerms(termFilter.value).then((tt) => terms.value = tt)
  }

  return { terms, termFilter, saveTerm, deleteTerm, reloadTerms }

  // --------------------------------------------------
  // Internal implementation

  function doSave(term: TermEdit): Promise<Term> {
    const termsApi = useTermsApi()
    if ('url' in term) {
      return termsApi.update(term as Term)
    } else {
      return termsApi.create(term)
    }
  }

  function setTerm(term: Term) {
    let updated = false
    const isDefault = term.default_term
    const newTerms = terms.value.reduce((tt: Term[], t: Term): Term[] => {
      if (t.id === term.id) {
        updated = true
        tt.push(term)
      } else {
        if (isDefault) {
          t.default_term = false
        }
        tt.push(t)
      }
      return tt
    }, [])
    if (!updated) {
      newTerms.push({ ...term} )
    }
    terms.value = newTerms
  }

  function removeTerm(term: Term) {
    terms.value = terms.value.filter((t) => t.id != term.id)
  }
})
