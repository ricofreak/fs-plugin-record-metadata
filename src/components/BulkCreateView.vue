<template>
  <div>
    <h2>Add entries in bulk</h2>

    <fieldset class="rows fs-bulk-form">
      <ol>
        <li>
          <label for="bulk_owning_institution">Owning institution:</label>
          <AvSelect id="bulk_owning_institution" field="owning_institution" v-model="owningInstitution" />
        </li>
        <li>
          <label for="bulk_scan_site">Scan site:</label>
          <AvSelect id="bulk_scan_site" field="scan_site" v-model="scanSite" />
        </li>
        <li>
          <label for="bulk_tns">Title numbers (TN):</label>
          <textarea id="bulk_tns" v-model="tnText" rows="6" placeholder="One per line"></textarea>
        </li>
        <li>
          <label for="bulk_barcodes">Barcodes:</label>
          <textarea id="bulk_barcodes" v-model="barcodeText" rows="6" placeholder="One per line"></textarea>
        </li>
      </ol>
        <table v-if="rows.length" class="table table-responsive table-success">
          <thead>
            <tr>
              <th><input type="checkbox" :checked="allSelected" @change="toggleAll($event.target.checked)" /></th>
              <th>TN</th>
              <th>Title</th>
              <th>Privacy (998$f)</th>
              <th>Contract (542$r)</th>
              <th>Ex 108 (506$a)</th>
              <th>Copyright (542$l)</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(r, idx) in rows" :key="idx" :class="rowClass(r)">
              <td><input type="checkbox" v-model="r.selected" :disabled="!r.selectable" /></td>
              <td>{{ r.biblionumber }}</td>
              <td>{{ r.title }}</td>
              <td>{{ r.privacy_998f }}</td>
              <td>{{ r.contract_542r }}</td>
              <td>{{ r.ex_108 }}</td>
              <td>{{ r.copyright_542l }}</td>
              <td>{{ statusText(r)}}</td>
            </tr>
          </tbody>
        </table>
    </fieldset>

    <fieldset class="action">
      <button class="btn btn-default" type="button" :disabled="!itemCount || loading" @click="preview">
        {{ loading ? "Checking…" : `Review ${itemCount} record${itemCount === 1 ? "" : "s"}` }}
      </button>
      <button class="btn btn-primary" type="button" :disabled="!selectedCount || saving" @click="create">
        {{ saving ? "Creating…" : `Create ${selectedCount} entr${selectedCount === 1 ? "y" : "ies"}` }}
      </button>
      <button v-if="rows.length" class="btn btn-default" type="button" @click="reset">Clear</button>
    </fieldset>


    <p v-if="error" class="fsrm-error">{{ error }}</p>

    <p v-if="summary.created || summary.skipped || summary.failed">
      <strong>{{ summary.created }}</strong> created,
      <strong>{{ summary.skipped }}</strong> skipped,
      <strong>{{ summary.failed }}</strong> failed.
    </p>

  </div>
</template>

<script>
import { previewEntries, createEntries } from "../api";

export default {
  name: "BulkCreateView",
  data() {
    return {
      owningInstitution: null,
      scanSite: null,
      tnText: "",
      barcodeText: "",
      rows: [],
      summary: { created: 0, skipped: 0, failed: 0 },
      loading: false,
      saving: false,
      error: null,
    };
  },
  computed: {
    items() {
      const split = (text) => text.split(/[\r\n,]+/).map((s) => s.trim()).filter(Boolean);
      return [
        ...split(this.tnText).map((value) => ({ type: "biblionumber", value })),
        ...split(this.barcodeText).map((value) => ({ type: "barcode", value })),
      ];
    },
    itemCount() {
      return this.items.length;
    },
    readyCount() {
      return this.rows.filter((r) => r.selectable).length;
    },
    selectedCount() {
      return this.rows.filter((r) => r.selected).length;
    },
    allSelected() {
      return this.readyCount > 0 && this.selectedCount === this.readyCount;
    },
  },
  methods: {
    statusText(r) {
      if (r.created) return "Created";
      if (r.status === "ready") return "Ready";
      return r.message;
    },
    rowClass(r) {
      if (r.created) return "fsrm-bulk-ok";
      if (r.status === "ready") return "fsrm-bulk-ready";
      if (r.status === "error") return "fsrm-bulk-error";
      return "fsrm-bulk-skip";
    },
    toggleAll(checked) {
      for (const r of this.rows) {
        if (r.selectable) r.selected = checked;
      }
    },
    async preview() {
      this.loading = true;
      this.error = null;
      this.summary = { created: 0, skipped: 0, failed: 0 };
      try {
        const body = await previewEntries({ items: this.items });
        this.rows = (body.results || []).map((r) => ({
          ...r,
          selected: !!r.selectable,
          created: false,
        }));
      } catch (e) {
        this.error = e.message;
      } finally {
        this.loading = false;
      }
    },
    async create() {
      this.saving = true;
      this.error = null;
      try {
        const chosen = this.rows.filter((r) => r.selected);

        const body = await createEntries({
          owning_institution: this.owningInstitution || null,
          scan_site: this.scanSite || null,
          items: chosen.map((r) => ({ type: "biblionumber", value: String(r.biblionumber), itemnumber: r.itemnumber || null })),
        });

        this.summary = body.summary || { created: 0, skipped: 0, failed: 0 };

        // fold results back into the rows they came from
        const byBiblio = {};
        for (const res of body.results || []) byBiblio[res.biblionumber] = res;

        for (const r of this.rows) {
          const res = byBiblio[r.biblionumber];
          if (!res) continue;
          r.created = res.status === "created";
          r.status = res.status;
          r.message = res.message;
          r.selected = false;
          r.selectable = false;
        }
      } catch (e) {
        this.error = e.message;
      } finally {
        this.saving = false;
      }
    },
    reset() {
      this.tnText = "";
      this.barcodeText = "";
      this.rows = [];
      this.summary = { created: 0, skipped: 0, failed: 0 };
      this.error = null;
    },
  },
};
</script>

<style>
.fs-bulk-form {
    display: grid;
    grid-template-columns: 1fr 3fr;
}
</style>
