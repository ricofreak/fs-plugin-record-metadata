<template>
  <div>
    <p v-if="error" class="fsrm-error">{{ error }}</p>

    <DataTable :options="tableOptions" class="display" width="100%">
      <thead>
        <tr>
          <th>#</th>
          <th>TN</th>
          <th>DTN</th>
          <th>Title</th>
          <th>Step</th>
          <th>Status</th>
          <th>Reason</th>
          <th>Description</th>
          <th>Problem date</th>
          <th>Initials</th>
          <th>Scan date</th>
          <th>OCR site</th>
        </tr>
      </thead>
    </DataTable>
  </div>
</template>

<script>
import DataTable from 'datatables.net-vue3';
import DataTablesCore from 'datatables.net-dt';
import 'datatables.net-dt/css/dataTables.dataTables.min.css';

import { getProblemsPaged } from "../api";

DataTable.use(DataTablesCore);

export default {
  name: 'ProblemsView',
  components: { DataTable },
  data() {
    return { error: null };
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
          { data: 'step', defaultContent: '' },
          { data: 'status', defaultContent: '' },
          { data: 'reason', defaultContent: '' },
          { data: 'description', defaultContent: '' },
          { data: 'problem_date', defaultContent: '' },
          { data: 'initials', defaultContent: '' },
          { data: 'scan_date', defaultContent: '' },
          { data: 'ocr_site', defaultContent: '' },
        ],
      };
    },
  },
};
</script>
