import { defineStore } from "pinia";
import { Ref, ref } from "vue";
import { FlashLevel, FlashMessage } from "../types/FlashMessage";

export const useFlashStore = defineStore('flash', () => {
  const messages: Ref<FlashMessage[]> = ref([])

  function setMessage(text: string, level: FlashLevel = 'success') {
    const newMessage: FlashMessage = { level, text }
    messages.value = [newMessage]
  }

  function clearMessages() {
    messages.value = []
  }

  return { messages, setMessage, clearMessages }
})
