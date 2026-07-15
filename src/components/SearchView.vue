<template>
  <div>
    <form @submit.prevent="runSearch" class="fsrm-search">
      <select v-model="searchType">
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" :placeholder="placeholder" />
      <button type="submit" :disabled="!searchTerm">Search</button>
    </form>

    <p v-if="error" class="fsrm-error">{{ error }}</p>

    <DataTable
      v-if="activeSearch"
      :key="tableKey"
      :options="tableOptions"
      class="display"
      width="100%"
    >
      <thead>
        <tr>
          <th>Entry</th><th>TN</th><th>DTN</th><th>Title/Author</th>
          <th>Barcode</th><th>Call number</th><th>Published</th>
        </tr>
      </thead>
    </DataTable>
  </div>
</template>

<script>
import DataTable from 'datatables.net-vue3';
import DataTablesCore from 'datatables.net-dt';
import 'datatables.net-dt/css/dataTables.dataTables.min.css';

DataTable.use(DataTablesCore);

const API_BASE = '/api/v1/contrib/fsrecordmetadata';

export default {
  name: 'SearchView',
  components: { DataTable },
  data() {
    return {
      searchType: 'biblionumber',
      searchTerm: '',
      activeSearch: null,   // frozen copy of the submitted search
      tableKey: 0,
      error: null,
    };
  },
  computed: {
    placeholder() {
      return this.searchType === 'biblionumber' ? 'e.g. 1234' : 'e.g. 39999000001234';
    },
    tableOptions() {
      const search = this.activeSearch;
      const setError = (msg) => { this.error = msg; };
      return {
        serverSide: true,
        processing: true,
        searching: false,   // our form is the search; hide DT's own box
        pageLength: 50,
        lengthMenu: [25, 50, 100],
        ordering: false,    // server orders by entry_id DESC; per-column sort is a later increment
        ajax: async (data, callback) => {
          try {
            const page = Math.floor(data.start / data.length) + 1;
            const params = new URLSearchParams({
              [search.type]: search.term,
              _page: page,
              _per_page: data.length,
            });
            const res = await fetch(`${API_BASE}/entries?${params}`, {
              headers: { Accept: 'application/json' },
              credentials: 'same-origin',
            });
            if (!res.ok) {
              const body = await res.json().catch(() => ({}));
              throw new Error(body.error || `Search failed (${res.status})`);
            }
            const total = parseInt(res.headers.get('X-Total-Count') || '0', 10);
            const rows = await res.json();
            callback({
              draw: data.draw,
              data: rows,
              recordsTotal: total,
              recordsFiltered: total,
            });
          } catch (e) {
            setError(e.message);
            callback({ draw: data.draw, data: [], recordsTotal: 0, recordsFiltered: 0 });
          }
        },
        columns: [
          { data: 'entry_id' },
          { data: 'biblionumber' },
          { data: 'dtn', defaultContent: '' },
          { data: 'title_author', defaultContent: '' },
          { data: 'barcode', defaultContent: '' },
          { data: 'callnumber', defaultContent: '' },
          { data: 'published', render: (d) => (d ? 'Yes' : 'No') },
        ],
      };
    },
  },
  methods: {
    runSearch() {
      this.error = null;
      this.activeSearch = { type: this.searchType, term: this.searchTerm };
      this.tableKey += 1;   // remount the table so a new search starts at page 1
    },
  },
};
</script>

<style>
.fsrm-search { display: flex; gap: .5rem; margin-bottom: 1rem; }
.fsrm-error { color: #b00; }
</style>
