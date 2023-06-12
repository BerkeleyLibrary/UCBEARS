<script setup lang="ts">
import {useFlashStore} from "../stores/flash-store";
import {storeToRefs} from "pinia";
import {computed, ComputedRef} from "vue";
import dismissIcon from '../../assets/images/icons/times-circle.svg';

const flashStore = useFlashStore()
const { messages } = storeToRefs(flashStore)

const hasMessages: ComputedRef<boolean> = computed(() => {
  const msgs = messages.value
  return msgs && msgs.length > 0
})
</script>

<template>
  <aside v-if="hasMessages">
    <div v-for="(message, index) in messages" :key="message.text" class="flash-message">
      <input
        :id="`flash-dismiss-${index}`"
        v-model="messages"
        type="checkbox"
        :value="message"
        class="flash-dismiss"
        checked
      >
      <div :class="`flash ${message.level}`">
        <label :for="`flash-dismiss-${index}`" class="flash-dismiss-label">
          <img :src="dismissIcon" class="flash-dismiss-icon" alt="Hide alert">
        </label>
        <p class="flash" role="alert">{{ message.text }}</p>
      </div>
    </div>
  </aside>
</template>
