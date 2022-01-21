<template>
  <aside
    v-if="Array.isArray(errors) && errors.length"
    class="flash"
  >
    <template v-for="(error, index) in errors">
      <input
        :id="`flash-dismiss-items-table-${index}`"
        :key="error"
        type="checkbox"
        class="flash-dismiss"
        @change="dismiss(index)"
      >
      <div :key="error" class="flash alert">
        <label
          :for="`flash-dismiss-items-table-${index}`"
          class="flash-dismiss-label"
        >
          <img
            src="/assets/icons/times-circle.svg"
            class="flash-dismiss-icon"
            alt="Hide alert"
          >
        </label>
        <p
          class="flash"
          role="alert"
        >
          {{ error }}
        </p>
      </div>
    </template>
  </aside>
</template>

<script>
export default {
  props: {
    errors: { type: Array, default: () => [] }
  },
  methods: {
    dismiss (index) {
      this.$emit('dismissed', index)
    }
  }
}
</script>
