<template>
  <div>
    <p v-if="error" class="fsrm-error">{{ error }}</p>
    <DataTable ref="table" :options="tableOptions" class="display" width="100%">
      <thead>
        <tr>
          <th>#</th>
          <th>TN</th>
          <th>DTN</th>
          <th>Title</th>
          <th>Status</th>
          <th>Problem type</th>
          <th>Description</th>
          <th>Problem date</th>
          <th>Solution</th>
          <th>Solution date</th>
        </tr>
      </thead>
    </DataTable>
    <ProblemsModal
      v-if="editingProblem"
      :entry-id="editingProblem.entry_id"
      :problem-id="editingProblem.problem_id"
      :dtn="editingProblem.dtn"
      @saved="onProblemSaved"
      @cancel="editingProblem = null"
    />
  </div>
</template>

<script>
import DataTable from 'datatables.net-vue3';
import DataTablesCore from 'datatables.net-dt';
import 'datatables.net-dt/css/dataTables.dataTables.min.css';

import { getProblemsPaged } from "../api";
import ProblemsModal from "./ProblemsModal.vue";

DataTable.use(DataTablesCore);

export default {
  name: 'ProblemsView',
  components: { DataTable, ProblemsModal },
  data() {
    return { 
      error: null,
      editingProblem: null,
      table: null,
    };
  },
  methods: {
    openProblem(row) {
      this.editingProblem = {
        problem_id: row.problem_id,
        entry_id: row.entry_id,
        dtn: row.dtn,
      };
    },

    onProblemSaved() {
      this.editingProblem = null;
      this.reloadTable();
    },
    reloadTable() {
      const dt = this.$refs.table && this.$refs.table.dt;
      if (dt && dt.ajax) dt.ajax.reload(null, false);
    },
  },
  computed: {
    tableOptions() {
      const setError = (msg) => { this.error = msg; };
      return {
        serverSide: true,
        processing: true,
        searching: false,
        ordering: false,
        pageLength: 50,
        lengthMenu: [25, 50, 100],
        createdRow: (row, data) => {
          row.style.cursor = "pointer";
          row.addEventListener("click", () => this.openProblem(data));
        },
        ajax: async (data, callback) => {
          try {
            const page = Math.floor(data.start / data.length) + 1;
            const { rows, total } = await getProblemsPaged({
              _page: page,
              _per_page: data.length,
            });
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
          { data: 'problem_id' },
          { data: 'biblionumber' },
          { data: 'dtn', defaultContent: '' },
          { data: 'title', defaultContent: '' },
          { data: 'status', defaultContent: '' },
          { data: 'problem_type', defaultContent: '' },
          { data: 'problem_description', defaultContent: '' },
          { data: 'problem_date', defaultContent: '' },
          { data: 'solution', defaultContent: '' },
          { data: 'solution_date', defaultContent: '' },
        ],
      };
    },
  },
};
</script>
