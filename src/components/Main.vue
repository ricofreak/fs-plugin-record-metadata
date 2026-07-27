<template>
  <div class="fs-record-metadata">
    <NavBar :current="view" @navigate="view = $event" />
    <SearchView v-if="view === 'search'" />
    <CreateView v-if="view === 'new'" />
    <NewEntry v-if="view === 'create' && canEdit" @saved="view = 'search'" @cancel="view = 'search'" />
  </div>
</template>

<script>
import SearchView from './SearchView.vue';
import CreateView from './CreateView.vue';
import NewEntry from './NewEntry.vue';

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
