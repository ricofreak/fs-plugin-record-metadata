<template>
  <nav class="fsrm_nav">
    <ul class="nav nav-tabs" role="tablist">
      <li
        v-for="item in items"
        :key="item.id"
        class="nav-item"
        role="presentation"
      >
        <a
          class="nav-link"
          :class="{ active: item.id === current }"
          href="#"
          role="tab"
          @click.prevent="$emit('navigate', item.id)"
          ><span>{{ item.label }}</span></a
        >
      </li>
    </ul>
  </nav>
</template>

<script>
export default {
  name: "NavBar",
  props: {
    current: { type: String, required: true },
  },
  emits: ["navigate"],
  computed: {
    items() {
      const all = [
        { id: "search", label: "Search" },
        { id: "new", label: "Add entry" },
        { id: "bulknew", label: "Bulk add entry" },
        { id: "create", label: "Processing - Step 1" },
        { id: "create2", label: "Processing - Step 2"},
        { id: "problems", label: "Problems" },
        { id: "reports", label: "Queues/reports" },
        { id: "admin", label: "Admin" },
      ];
      return all;
    },
  },
};
</script>
<style>
.fsrm_nav {
  margin-bottom: 1em;
}
</style>
