<template>
  <aside v-if="hasMessages" id="flash" class="flash">
    <div v-for="(message, index) in _messages" :key="message.text" class="flash-message">
      <input
        :id="`flash-dismiss-${index}`"
        v-model="_messages"
        type="checkbox"
        :value="message"
        class="flash-dismiss"
        checked
      >
      <div :class="`flash ${message.level}`">
        <label :for="`flash-dismiss-${index}`" class="flash-dismiss-label">
          <img src="/assets/icons/times-circle.svg" class="flash-dismiss-icon" alt="Hide alert">
        </label>
        <p class="flash" role="alert">{{ message.text }}</p>
      </div>
    </div>
  </aside>
</template>

<script>

export default {
  props: {
    messages: { type: Array, default: () => [] }
  },
  computed: {
    _messages: {
      get () {
        console.log('_messages.get()')
        const msgs = [...this.messages]
        console.log(msgs)
        return msgs
      },
      set (messages) { this.$emit('updated', messages) }
    },
    hasMessages () {
      return !!this.messages && this.messages.length > 0
    }
  }
}
</script>
