<template>
  <aside v-if="hasErrors" class="flash">
    <div v-for="(message, index) in messages" :key="message" style="display: contents;">
      <input
        :id="`flash-dismiss-${index}`"
        :key="message"
        v-model="messages"
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
    errors: { type: Array, default: () => [] }
  },
  computed: {
    messages: {
      get () { return this.errors },
      set (errors) { this.$emit('updated', errors) }
    },
    hasErrors () {
      return !!this.messages && this.messages.length > 0
    }
  }
}
</script>
