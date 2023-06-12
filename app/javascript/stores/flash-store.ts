import {defineStore} from "pinia";
import {Ref, ref} from "vue";
import {FlashMessage} from "../types/FlashMessage";

export const useFlashStore = defineStore('flash', () => {
  const messages: Ref<FlashMessage[]> = ref([])

  return { messages }
})
