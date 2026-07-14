<template>
  <div class="fs-record-metadata">
    <h1>Record Metadata</h1>

    <NavBar :current="view" @navigate="view = $event" />

    <SearchView v-if="view === 'search'" />
    <p v-else-if="view === 'create' && canEdit">New entry form goes here.</p>
    <p v-else-if="view === 'reports'">Reports go here.</p>
    <p v-else>You don't have permission to view this page.</p>

  </div>
</template>

<script>
import SearchView from './SearchView.vue';

export default {
  name: 'Main',
  components: { SearchView },
  data() {
    return { view: 'search' };
  },
  computed: {
    canEdit() {
      return (window.fsrmPermissions || {}).canEdit === true;
    },
  },
};
</script>

<style>
.fs-record-metadata { padding: 1rem; }
</style>
