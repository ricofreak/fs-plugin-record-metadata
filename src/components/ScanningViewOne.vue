<template>
  <div>
    <form @submit.prevent="search" class="fsrm-search">
      <select>
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" placeholder="Find an entry" />
      <button type="submit" class="btn btn-primary" :disabled="!searchTerm || loading">
        {{ loading ? 'Searching…' : 'Find entry' }}
      </button>
    </form>

    <p v-if="error" class="fsrm-error">{{ error }}</p>
    <p v-if="searched && !entries.length && !loading">No entries found. Create one first.</p>
    <fieldset v-if="entries.length">
        <h2>Entries</h2>
        <table class="fsrm-items table table-success table-responsive">
          <thead>
            <tr>
              <th></th>
              <th>DTN</th>
              <th>TN</th>
              <th>Title</th>
              <th>Access</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="e in entries"
              :key="e.entry_id"
              :class="{ selected: selected && e.entry_id === selected.entry_id }"
              @click="select(e)"
            >
              <td><input type="radio" :value="e.entry_id" :checked="selected && selected.entry_id === e.entry_id" /></td>
              <td>{{ e.dtn }}</td>
              <td>{{ e.biblionumber }}</td>
              <td>{{ e.title }}</td>
              <td>{{ e.access }}</td>
            </tr>
          </tbody>
        </table>
    </fieldset>

    <div v-if="selected">
      <h2>DTN: {{ selected.dtn }}</h2>

      <fieldset class="rows">
        <ol>
          <li><span class="label">Title:</span> {{ selected.title }}</li>
          <li><span class="label">Author:</span> {{ selected.author }}</li>
          <li><span class="label">Barcodes:</span> {{ selected.barcodes }}</li>
          <li><span class="label">Call #:</span> {{ selected.callnumbers }}</li>
        </ol>
      </fieldset>

      <fieldset class="rows">
        <legend>Processing status</legend>
        <ol>
          <li>
            <label for="access">Digital title number:</label>
            <input id="dtn" v-model.trim="form.access" />
          </li>
          <li>
            <label for="access">Access:</label>
            <input id="access" v-model.trim="form.access" />
          </li>
        </ol>
      </fieldset>

      <fieldset class="action">
        <button class="btn btn-primary" :disabled="saving" @click="save">
          {{ saving ? 'Saving…' : 'Save' }}
        </button>
        <span v-if="savedAt" class="fsrm-saved">Saved.</span>
      </fieldset>
    </div>
  </div>
</template>

<script>
const API_BASE = '/api/v1/contrib/fsrecordmetadata';

export default {
  name: 'ScanningView',
  data() {
    return {
      searchType: 'biblionumber',
      searchTerm: '',
      entries: [],
      selected: null,
      form: {},
      searched: false,
      loading: false,
      saving: false,
      savedAt: null,
      error: null,
    };
  },
  methods: {
    async search() {
      this.loading = true;
      this.error = null;
      this.entries = [];
      this.selected = null;
      this.savedAt = null;
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
      this.form = {
        access: entry.access || '',
      };
    },
    async save() {
      this.saving = true;
      this.error = null;
      this.savedAt = null;
      try {
        const payload = {
          md_date: this.form.md_date || null,
          md_by: this.form.md_by || null,
          scan_site: this.form.scan_site || null,
          scan_operator_by: this.form.scan_operator_by || null,
          scan_machine: this.form.scan_machine || null,
          scan_date: this.form.scan_date || null,
          scan_site_notes: this.form.scan_site_notes || null,
          scanned_image_count: this.form.scanned_image_count || null,
        };

        const res = await fetch(`${API_BASE}/entries/${this.selected.entry_id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          credentials: 'same-origin',
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `Save failed (${res.status})`);
        }
        const updated = await res.json();
        const idx = this.entries.findIndex(e => e.entry_id === updated.entry_id);
        if (idx !== -1) this.entries.splice(idx, 1, updated);
        this.selected = updated;
        this.savedAt = Date.now();
      } catch (e) {
        this.error = e.message;
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>
