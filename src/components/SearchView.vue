<template>
    <div>
        <form @submit.prevent="search" class="fsrm-search">
          <select v-model="searchType">
            <option value="biblionumber">TN (biblionumber)</option>
            <option value="barcode">Barcode</option>
          </select>
          <input v-model.trim="searchTerm" :placeholder="placeholder" />
          <button type="submit" :disabled="!searchTerm || loading">
            {{ loading ? 'Searching…' : 'Search' }}
          </button>
        </form>

        <p v-if="error" class="fsrm-error">{{ error }}</p>

        <table v-if="searched && entries.length" class="fsrm-results">
          <thead>
            <tr>
              <th>Entry</th>
              <th>TN</th>
              <th>DTN</th>
              <th>Title/Author</th>
              <th>Barcode</th>
              <th>Call number</th>
              <th>Published</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="e in entries" :key="e.entry_id">
              <td>{{ e.entry_id }}</td>
              <td>{{ e.biblionumber }}</td>
              <td>{{ e.dtn }}</td>
              <td>{{ e.title_author }}</td>
              <td>{{ e.barcode }}</td>
              <td>{{ e.callnumber }}</td>
              <td>{{ e.published ? 'Yes' : 'No' }}</td>
            </tr>
          </tbody>
        </table>

        <p v-else-if="searched && !loading && !error">No entries found.</p>
    </div>
</template>
<script>
const API_BASE = '/api/v1/contrib/fsrecordmetadata';

export default {
  name: 'App',
  data() {
    return {
      searchType: 'biblionumber',
      searchTerm: '',
      entries: [],
      searched: false,
      loading: false,
      error: null,
    };
  },
  computed: {
    placeholder() {
      return this.searchType === 'biblionumber' ? 'e.g. 1234' : 'e.g. 39999000001234';
    },
  },
  methods: {
    async search() {
      this.loading = true;
      this.error = null;
      this.entries = [];
      try {
        const params = new URLSearchParams({ [this.searchType]: this.searchTerm });
        const res = await fetch(`${API_BASE}/entries?${params}`, {
          headers: { Accept: 'application/json' },
          credentials: 'same-origin',
        });
        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `Search failed (${res.status})`);
        }
        this.entries = await res.json();
      } catch (e) {
        this.error = e.message;
      } finally {
        this.searched = true;
        this.loading = false;
      }
    },
  },
};
</script>

<style>
.fsrm-search { display: flex; gap: .5rem; margin-bottom: 1rem; }
.fsrm-error { color: #b00; }
.fsrm-results { border-collapse: collapse; width: 100%; }
.fsrm-results th, .fsrm-results td { border: 1px solid #ccc; padding: .4rem .6rem; text-align: left; }
</style>
