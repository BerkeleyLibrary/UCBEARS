<template>
  <aside v-if="hasErrors" class="flash">
    <div v-for="(message, index) in error_messages" :key="message" style="display: contents;">
      <input
        :id="`flash-dismiss-${index}`"
        :key="message"
        v-model="error_messages"
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

function normalizeErrorMessage (attr, msg) {
  if (attr === 'base') {
    return msg
  }
  return `${attr} ${msg}`
}

export default {
  props: {
    errors: { type: Object, default: () => {} }
  },
  computed: {
    error_messages: {
      get () {
        const errors = this.errors
        if (!errors) {
          return []
        }
        if (Array.isArray(errors)) {
          return errors
        }
        return Object.entries(errors).flatMap(([k, v]) => normalizeErrorMessage(k, v))
      },
      set (errors) { this.$emit('updated', errors) }
    },
    hasErrors () {
      return !!this.error_messages && this.error_messages.length > 0
    }
  }
}
</script>
