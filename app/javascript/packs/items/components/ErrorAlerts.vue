<template>
  <aside class="flash">
    <div v-for="(error, index) in _errors" :key="error" style="display: contents;">
      <input
        :id="`flash-dismiss-${index}`"
        :key="error"
        v-model="_errors"
        type="checkbox"
        :value="error"
        class="flash-dismiss"
        checked
      >
      <div class="flash alert">
        <label :for="`flash-dismiss-${index}`" class="flash-dismiss-label">
          <img src="/assets/icons/times-circle.svg" class="flash-dismiss-icon" alt="Hide alert">
        </label>
        <p class="flash" role="alert">{{ error }}</p>
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
    _errors: {
      get () { return this.errors },
      set (errors) { this.$emit('updated', errors) }
    }
  }
}
</script>
