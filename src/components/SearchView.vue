<template>
  <div>
    <form @submit.prevent="runSearch" class="fsrm-search">
      <select v-model="searchType">
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" placeholder="Search for an entry" />
      <button type="submit" class="btn btn-primary" :disabled="!searchTerm">
        Search
      </button>
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
          <th title="problems">Problems</th>
          <th title="Title number">TN</th>
          <th title="Digital title number">DTN</th>
          <th title="Title and author">Title/Author</th>
          <th title="Item type">Item type</th>
          <th title="Digital access">Access</th>
          <th title="Call number">Call #</th>
          <th title="Item barcode">Barcode</th>
          <th title="Metadata">MD</th>
          <th title="Scanned">Scan</th>
          <th title="Audit1">A1</th>
          <th title="Audit2">A2</th>
          <th title="OCR">OCR</th>
          <th title="Published date">Pub</th>
          <th title="Online review">OR</th>
        </tr>
      </thead>
    </DataTable>
  </div>
</template>

<script>
import DataTable from "datatables.net-vue3";
import DataTablesCore from "datatables.net-dt";
import "datatables.net-dt/css/dataTables.dataTables.min.css";

DataTable.use(DataTablesCore);

const API_BASE = "/api/v1/contrib/fsrecordmetadata";

const iconToggle = (d) =>
  d
    ? '<i class="fa fa-check fsrm-flag-yes" aria-hidden="true"></i>'
    : '<i class="fa fa-times fsrm-flag-no" aria-hidden="true"></i>';

export default {
  name: "SearchView",
  components: { DataTable },
  data() {
    return {
      searchType: "biblionumber",
      searchTerm: "",
      activeSearch: null, // frozen copy of the submitted search
      tableKey: 0,
      error: null,
    };
  },
  computed: {
    tableOptions() {
      const search = this.activeSearch;
      const setError = (msg) => {
        this.error = msg;
      };
      return {
        serverSide: true,
        processing: true,
        searching: false, // our form is the search; hide DT's own box
        pageLength: 50,
        lengthMenu: [25, 50, 100],
        ordering: false, // server orders by entry_id DESC; per-column sort is a later increment
        ajax: async (data, callback) => {
          try {
            const page = Math.floor(data.start / data.length) + 1;
            const params = new URLSearchParams({
              [search.type]: search.term,
              _page: page,
              _per_page: data.length,
            });
            const res = await fetch(`${API_BASE}/entries?${params}`, {
              headers: { Accept: "application/json" },
              credentials: "same-origin",
            });
            if (!res.ok) {
              const body = await res.json().catch(() => ({}));
              throw new Error(body.error || `Search failed (${res.status})`);
            }
            const total = parseInt(res.headers.get("X-Total-Count") || "0", 10);
            const rows = await res.json();
            callback({
              draw: data.draw,
              data: rows,
              recordsTotal: total,
              recordsFiltered: total,
            });
          } catch (e) {
            setError(e.message);
            callback({
              draw: data.draw,
              data: [],
              recordsTotal: 0,
              recordsFiltered: 0,
            });
          }
        },
        columns: [
          { data: "problem_id", defaultContent: "" },
          { data: "biblionumber" },
          { data: "dtn", defaultContent: "" },
          {
            data: null,
            render: (row) =>
              [row.title, row.author].filter(Boolean).join(" / "),
          },
          { data: "itypes", defaultContent: "" },
          { data: "access", defaultContent: "" },
          { data: "callnumber", defaultContent: "" },
          { data: "barcodes", defaultContent: "" },
          { data: "md", render: iconToggle },
          { data: "scan", render: iconToggle },
          { data: "a1", render: iconToggle },
          { data: "a2", render: iconToggle },
          { data: "orc", render: iconToggle },
          { data: "published", render: iconToggle },
          { data: "or", render: iconToggle },
        ],
      };
    },
  },
  methods: {
    runSearch() {
      this.error = null;
      this.activeSearch = { type: this.searchType, term: this.searchTerm };
      this.tableKey += 1; // remount the table so a new search starts at page 1
    },
  },
};
</script>

<style>
.fsrm-saved {
  margin-left: 1rem;
  color: #418940;
}
.fsrm-search {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}
.fsrm-error {
  color: #b00;
}
.fsrm-flag-yes {
  color: #418940;
  font-weight: bold;
}
.fsrm-flag-no {
  color: #c00;
}
td.fsrm-flag-col {
  text-align: center;
}
</style>
