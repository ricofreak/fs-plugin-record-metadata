<template>
  <div>
    <form @submit.prevent="search" class="fsrm-search">
      <select v-model="searchType">
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" placeholder="Find an entry" />
      <button type="submit" class="btn btn-primary" :disabled="!searchTerm || loading">
        {{ loading ? "Searching…" : "Find entry" }}
      </button>
    </form>

    <p v-if="error" class="fsrm-error">{{ error }}</p>
    <p v-if="searched && !entries.length && !loading">
      No entries found. Create one first.
    </p>

    <fieldset v-if="entries.length">
      <h2>Entries</h2>
      <table class="fsrm-items table table-success table-responsive">
        <thead>
          <tr>
            <th></th><th>DTN</th><th>TN</th><th>Title</th><th>Access</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="e in entries"
            :key="e.entry_id"
            :class="{ selected: selected && e.entry_id === selected.entry_id }"
            @click="select(e)"
          >
            <td>
              <input type="radio" :value="e.entry_id"
                     :checked="selected && selected.entry_id === e.entry_id" />
            </td>
            <td>{{ e.dtn }}</td>
            <td>{{ e.biblionumber }}</td>
            <td>{{ e.title }}</td>
            <td>{{ e.access }}</td>
          </tr>
        </tbody>
      </table>
    </fieldset>

    <div v-if="selected">
      <h2>Digitial title number: {{ selected.dtn }}</h2>

      <slot
        name="fields"
        :form="form"
        :names="names"
        :selected="selected"
        :edit-problem="editProblem"
        :add-problem="addProblem"
      ></slot>

      <fieldset class="action">
        <div class="btn-toolbar">
          <button
            v-if="prevStep"
            class="btn btn-primary"
            type="button"
            :disabled="saving"
            @click="saveAndBack"
          >
            {{ saving ? "Saving…" : prevStepLabel }}
          </button>
          <button class="btn btn-primary" :disabled="saving" @click="save">
            {{ saving ? "Saving…" : "Save" }}
          </button>
          <button
            v-if="nextStep"
            class="btn btn-primary"
            type="button"
            :disabled="saving"
            @click="saveAndGo"
          >
            {{ saving ? "Saving…" : nextStepLabel }}
          </button>
          <p v-if="error" class="error" role="alert">{{ error }}</p>
          <span v-if="savedAt" class="fsrm-saved">Saved.</span>
        </div>
      </fieldset>
    </div>

    <ProblemsModal
      v-if="showProblemsModal && selected"
      :entry-id="selected.entry_id"
      :dtn="selected.dtn"
      :problem-id="editingProblemId"
      @saved="onProblemSaved"
      @cancel="showProblemsModal = false"
    />
  </div>
</template>

<script>
import ProblemsModal from "./ProblemsModal.vue";
import { getEntries, updateEntry } from "../api";

export default {
  name: "ScanningForm",
  components: { ProblemsModal },
  props: {
    entry: { type: Object, default: null },
    fieldKeys: { type: Array, required: true },
    nextStep: { type: Number, default: null },
    nextStepLabel: { type: String, default: "Save and continue" },
    prevStep: { type: Number, default: null },
    prevStepLabel: { type: String, default: "Save and go back" },
  },
  emits: ["saved", "step", "cancel"],
  data() {
    return {
      searchType: "biblionumber",
      searchTerm: "",
      entries: [],
      selected: null,
      form: {},
      names: {},
      searched: false,
      loading: false,
      saving: false,
      savedAt: null,
      error: null,
      showProblemsModal: false,
      editingProblemId: null,
    };
  },
  created() {
    if (this.entry) this.select(this.entry);
  },
  watch: {
    entry(val) {
      if (val) this.select(val);
    },
  },
  methods: {
    async search() {
      this.loading = true;
      this.error = null;
      this.entries = [];
      this.selected = null;
      this.savedAt = null;
      try {
        this.entries = await getEntries({ [this.searchType]: this.searchTerm });
        if (this.entries.length === 1) this.select(this.entries[0]);
      } catch (e) {
        this.error = e.message;
      } finally {
        this.searched = true;
        this.loading = false;
      }
    },

    select(entry) {
      this.selected = entry;
      this.savedAt = null;
      const form = {};
      const names = {};
      for (const key of this.fieldKeys) {
        form[key] = entry[key] === null || entry[key] === undefined ? "" : entry[key];
        if (key.endsWith("_by")) names[key] = entry[key.replace(/_by$/, "_name")] || "";
      }
      this.form = form;
      this.names = names;
    },

    buildPayload() {
      const payload = {};
      for (const key of this.fieldKeys) {
        const v = this.form[key];
        payload[key] = v === "" || v === undefined ? null : v;
      }
      return payload;
    },

    async save() {
      this.saving = true;
      this.error = null;
      this.savedAt = null;
      try {
        const updated = await updateEntry(this.selected.entry_id, this.buildPayload());
        const idx = this.entries.findIndex((e) => e.entry_id === updated.entry_id);
        if (idx !== -1) this.entries.splice(idx, 1, updated);
        this.select(updated);
        this.savedAt = Date.now();
        return updated;
      } catch (e) {
        this.error = e.message;
        return null;
      } finally {
        this.saving = false;
      }
    },

    async saveAndGo() {
      const updated = await this.save();
      if (!updated) return;
      this.$emit("saved", updated);
      this.$emit("step", this.nextStep);
    },

    async saveAndBack() {
      const updated = await this.save();
      if (!updated) return;
      this.$emit("saved", updated);
      this.$emit("step", this.prevStep);
    },

    editProblem(problemId) {
      this.editingProblemId = Number(problemId);
      this.showProblemsModal = true;
    },

    addProblem() {
      this.editingProblemId = null;
      this.showProblemsModal = true;
    },

    async onProblemSaved() {
      const entryId = this.selected.entry_id;
      this.showProblemsModal = false;
      await this.search();
      const again = this.entries.find((e) => e.entry_id === entryId);
      if (again) this.select(again);
    },
  },
};
</script>
