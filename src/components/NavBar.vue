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
        { id: "new", label: "New +" },
        { id: "create", label: "Scanning/processing (1)", requires: "canEdit" },
        { id: "create2", label: "Scanning/processing (2)", requires: "canEdit" },
        { id: "problems", label: "Problems" },
        { id: "reports", label: "Queues/reports" },
        { id: "admin", label: "Admin", requires: "canEdit" },
      ];
      const perms = window.fsrmPermissions || {};
      return all.filter((i) => !i.requires || perms[i.requires]);
    },
  },
};
</script>
<style>
.fsrm_nav {
  margin-bottom: 1em;
}
</style>
