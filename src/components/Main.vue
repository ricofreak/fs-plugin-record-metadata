<template>
  <div class="fs-record-metadata">
    <h1>Record Metadata</h1>

    <NavBar :current="view" @navigate="view = $event" />

    <SearchView v-if="view === 'search'" />
    <p v-else-if="view === 'create'">New entry form goes here.</p>
    <p v-else-if="view === 'reports'">Reports go here.</p>

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
};
</script>

<style>
.fs-record-metadata { padding: 1rem; }
.fsrm-search { display: flex; gap: .5rem; margin-bottom: 1rem; }
.fsrm-error { color: #b00; }
.fsrm-results { border-collapse: collapse; width: 100%; }
.fsrm-results th, .fsrm-results td { border: 1px solid #ccc; padding: .4rem .6rem; text-align: left; }
</style>

