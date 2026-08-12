<template>
  <div class="modal fade show fsrm-modal-backdrop" style="display: block;" @click.self="$emit('cancel')">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">{{ title }}</h5>
          <button type="button" class="btn-close" @click="$emit('cancel')"></button>
        </div>

        <div class="modal-body">
          <form @submit.prevent="lookup(term)" class="fsrm-search">
            <input ref="input" v-model.trim="term" placeholder="Surname, first name, or username" autocomplete="off" />
            <button type="submit" class="btn btn-primary" :disabled="term.length < 2 || loading">
              {{ loading ? "Searching…" : "Search" }}
            </button>
          </form>

          <p v-if="error" class="fsrm-error">{{ error }}</p>
          <p v-if="searched && !results.length && !loading">No matching staff found.</p>

          <table v-if="results.length" class="table table-responsive">
            <thead>
              <tr><th>Name</th><th>Username</th><th></th></tr>
            </thead>
            <tbody>
              <tr v-for="s in results" :key="s.borrowernumber">
                <td>{{ s.surname }}, {{ s.firstname }}</td>
                <td>{{ s.userid }}</td>
                <td><button type="button" class="btn btn-primary btn-sm" @click="$emit('choose', s)">Select</button></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-default" @click="$emit('cancel')">Cancel</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { searchStaff } from "../api";

export default {
  name: "StaffSearchModal",
  props: {
    title: { type: String, default: "Find staff member" },
  },
  emits: ["choose", "cancel"],
  data() {
    return { term: "", results: [], searched: false, loading: false, error: null };
  },
  mounted() {
    if (this.$refs.input) this.$refs.input.focus();
  },
  methods: {
    async lookup(term) {
      this.loading = true;
      this.error = null;
      this.results = [];
      try {
        this.results = await searchStaff(term);
      } catch (e) {
        this.error = e.status === 403
          ? "You don't have permission to search patrons."
          : e.message;
      } finally {
        this.searched = true;
        this.loading = false;
      }
    },
  },
};
</script>
