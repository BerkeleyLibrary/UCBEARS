<template>
  <aside v-if="errors && errors.size > 0" class="flash">
    <div v-for="(error, index) in errors" :key="error" style="display: contents;">
      <input
        :id="`flash-dismiss-items-table-${index}`"
        :key="error"
        type="checkbox"
        class="flash-dismiss"
        @change="dismiss(error)"
      >
      <div class="flash alert">
        <label :for="`flash-dismiss-items-table-${index}`" class="flash-dismiss-label">
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
    errors: { type: Set, default: () => new Set() }
  },
  methods: {
    dismiss (error) {
      this.$emit('dismissed', error)
    }
  }
}
</script>
