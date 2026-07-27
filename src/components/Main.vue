<template>
  <div class="fs-record-metadata">
    <NavBar :current="view" @navigate="view = $event" />
    <SearchView v-if="view === 'search'" />
    <CreateView v-if="view === 'new'" />
    <NewEntry v-else-if="view === 'create' && canEdit" @saved="view = 'search'" @cancel="view = 'search'" />
    <p v-else-if="view === 'reports'">Reports go here.</p>
    <p v-else>Nothing here yet!</p>
  </div>
</template>

<script>
import SearchView from './SearchView.vue';
import NewEntry from './NewEntry.vue';
import CreateView from './CreateView.vue';

export default {
  name: 'Main',
  components: { SearchView, NewEntry, CreateView },
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
