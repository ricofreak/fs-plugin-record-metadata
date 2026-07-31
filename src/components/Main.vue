<template>
  <div class="fs-record-metadata">
    <NavBar :current="view" @navigate="view = $event" />
    <SearchView v-if="view === 'search'" @select="openEntry" />
    <CreateView v-if="view === 'new'" @created="openEntry" />
    <ScanningViewOne
      v-if="view === 'create' && canEdit"
      :entry="entry"
      @saved="onSaved"
      @step="onStep"
      @cancel="closeEntry"
    />
    <ScanningViewTwo
      v-if="view === 'create2' && canEdit"
      :entry="entry"
      @saved="onSaved"
      @step="onStep"
      @cancel="closeEntry"
    />
  </div>
</template>

<script>
import SearchView from "./SearchView.vue";
import CreateView from "./CreateView.vue";
import ScanningViewOne from "./ScanningViewOne.vue";
import ScanningViewTwo from "./ScanningViewTwo.vue";

export default {
  name: "Main",
  components: { SearchView, CreateView, ScanningViewOne, ScanningViewTwo },
  data() {
    return { view: "search", entry: null };
  },
  computed: {
    canEdit() {
      return (window.fsrmPermissions || {}).canEdit === true;
    },
  },
  methods: {
    openEntry(entry) {
      this.entry = entry;
      this.view = "create";
    },
    onSaved(updated) {
      this.entry = updated;
    },
    onStep(n) {
      this.view = n === 2 ? "create2" : "create";
    },
    closeEntry() {
      this.entry = null;
      this.view = "search";
    },
  },
};
</script>

<style>
.fs-record-metadata {
  padding: 1rem;
}
</style>
