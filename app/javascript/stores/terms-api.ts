import axios, { AxiosRequestConfig } from 'axios'
import { defineStore } from 'pinia'
import { ref, Ref } from 'vue'
import { TermFilter } from "../types/TermFilter";
import { Term, TermEdit } from "../types/Term";
import { useFlashStore } from "./flash";

// TODO: Roll this into Terms store
export const useTermsApi = defineStore('terms-api', () => {
  const termsUrl: Ref<string> = ref(new URL('/terms.json', window.location.href).toString())

  function getAll(): Promise<Term[]>  {
    return findTerms()
  }

  function findTerms(filter: TermFilter = {}): Promise<Term[]> {
    const url = termsUrl.value;
    const requestConfig: AxiosRequestConfig = { headers: { Accept: 'application/json' } } // TODO: global Axios config?
    if (filter) {
      requestConfig.params = filter
    }
    return axios.get(url, requestConfig).then(response => response.data)
  }

  function create(term: TermEdit): Promise<Term> {
    const url = termsUrl.value;
    return axios.post(url, { term }).then(response => {
      const { setMessage } = useFlashStore()
      setMessage('Term added.')
      return response.data
    })
  }

  function update(term: Term): Promise<Term> {
    return axios.patch(term.url, { term }).then(response => {
      const { clearMessages } = useFlashStore()
      clearMessages()
      console.log('Term saved.')
      return response.data;
    })
  }

  function _delete(term: Term): Promise<Term> {
    return axios.delete(term.url).then(() => {
      const { setMessage } = useFlashStore()
      setMessage('Term deleted.')
      return term;
    })
  }

  // --------------------------------------------------
  // Store

  return { getAll, findTerms, create, update, delete: _delete }

})
