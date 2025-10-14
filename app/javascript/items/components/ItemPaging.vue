<template>
  <nav
    v-if="paging"
    class="pagination"
    aria-label="Pagination"
  >
    <ul>
      <li>
        <a
          v-if="paging.first && paging.currentPage !== 1"
          href="#"
          rel="first"
          title="First page"
          @click="navigateTo(paging.first)"
        >≪</a>
        <template v-else>
          ≪
        </template>
      </li>
      <li>
        <a
          v-if="paging.prev && paging.currentPage > 1"
          href="#"
          rel="prev"
          title="Previous page"
          @click="navigateTo(paging.prev)"
        >&lt;</a>
        <template v-else>
          &lt;
        </template>
      </li>
      <li>
        Page {{ paging.currentPage }} of {{ paging.totalPages }}
      </li>
      <li>
        <a
          v-if="paging.next && paging.currentPage < paging.totalPages"
          href="#"
          rel="next"
          title="Next page"
          @click="navigateTo(paging.next)"
        >&gt;</a>
        <template v-else>
          &gt;
        </template>
      </li>
      <li>
        <a
          v-if="paging.last && paging.currentPage !== paging.totalPages"
          href="#"
          rel="last"
          title="Last page"
          @click="navigateTo(paging.last)"
        >≫</a>
        <template v-else>
          ≫
        </template>
      </li>
    </ul>
  </nav>
</template>

<script>
export default {
  props: { paging: { type: Object, default: () => {} } },
  methods: {
    navigateTo (pageUrl) {
      this.$emit('page-selected', pageUrl)
    }
  }
}
</script>
