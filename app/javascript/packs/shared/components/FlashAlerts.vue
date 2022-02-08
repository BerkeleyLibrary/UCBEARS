<template>
  <aside v-if="hasMessages" class="flash">
    <div v-for="(message, index) in _messages" :key="message" style="display: contents;">
      <input
        :id="`flash-dismiss-${index}`"
        :key="message"
        v-model="_messages"
        type="checkbox"
        :value="message"
        class="flash-dismiss"
        checked
      >
      <div class="flash alert">
        <label :for="`flash-dismiss-${index}`" class="flash-dismiss-label">
          <img src="/assets/icons/times-circle.svg" class="flash-dismiss-icon" alt="Hide alert">
        </label>
        <p class="flash" role="alert">{{ message }}</p>
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
      get () { return this.messages },
      set (messages) { this.$emit('updated', messages) }
    },
    hasMessages () {
      return !!this.messages && this.messages.length > 0
    }
  }
}
</script>
