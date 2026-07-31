<template>
  <div class="fs-record-metadata">
    <NavBar :current="view" @navigate="view = $event" />
    <SearchView v-if="view === 'search'" @select="openEntry" />
    <CreateView v-if="view === 'new'" @created="openEntry" />
    <ScanningViewOne
      v-if="view === 'create' && canEdit && step === 1"
      :entry="entry"
      @saved="onSaved"
      @step="step = $event"
      @cancel="closeEntry"
    />
    <ScanningViewTwo
      v-if="view === 'create' && canEdit && step === 2"
      :entry="entry"
      @saved="onSaved"
      @step="step = $event"
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
    return { view: "search", step: 1, entry: null };
  },
  computed: {
    canEdit() {
      return (window.fsrmPermissions || {}).canEdit === true;
    },
  },
  watch: {
    view(v) {
      if (v !== "create") this.step = 1;
    },
  },
  methods: {
    openEntry(entry) {
      this.entry = entry;
      this.step = 1;
      this.view = "create";
    },
    onSaved(updated) {
      this.entry = updated;
    },
    closeEntry() {
      this.entry = null;
      this.step = 1;
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
