<template>
  <div class="fs-record-metadata">
    <NavBar :current="view" @navigate="view = $event" />
    <SearchView v-if="view === 'search'" />
    <CreateView v-if="view === 'new'" />
    <ScanningViewOne
      v-if="view === 'create' && canEdit"
      @saved="view = 'search'"
      @cancel="view = 'search'"
    />
  </div>
</template>

<script>
import SearchView from "./SearchView.vue";
import CreateView from "./CreateView.vue";
import ScanningViewOne from "./ScanningViewOne.vue";

export default {
  name: "Main",
  components: { SearchView, CreateView, ScanningViewOne },
  data() {
    return { view: "search" };
  },
  computed: {
    canEdit() {
      return (window.fsrmPermissions || {}).canEdit === true;
    },
  },
};
</script>

<style>
.fs-record-metadata {
  padding: 1rem;
}
</style>
