<template>
  <div>
    <form @submit.prevent="lookup" class="fsrm-search">
      <select v-model="searchType">
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" placeholder="Search for a record" />
      <button type="submit" class="btn btn-primary" :disabled="!searchTerm || loading">
        {{ loading ? 'Searching…' : 'Find record' }}
      </button>
    </form>

    <p v-if="error" class="fsrm-error">{{ error }}</p>

    <div v-if="record">
      <h2>Results</h2>
      <fieldset class="rows results">
        <div>
            <ol>
              <li><span class="label">Title:</span> {{ record.title }}</li>
              <li><span class="label">Author:</span> {{ record.author }}</li>
              <li><span class="label">Publisher Date:</span> {{ record.publication_date }}</li>
            </ol>
            <table class="table table-success table-responsive" v-if="record.online_links && record.online_links.length">
                <thead>
                    <tr>
                        <th>Online link</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(link, idx) in record.online_links" :key="idx">
                        <td>
                            <a :href="link.url" target="_blank" rel="noopener">{{ link.url }}</a>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <table class="fsrm-items table table-success table-responsive" v-if="record.items.length">
          <thead>
            <tr>
              <th>Item type</th>
              <th>Home library</th>
              <th>Call number</th>
              <th>Barcode</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="i in record.items"
              :key="i.itemnumber"
              :class="{ selected: i.itemnumber === selectedItemnumber }"
              @click="selectedItemnumber = i.itemnumber"
            >
              <td>{{ i.itemtype }}</td>
              <td>{{ i.branchname || i.homebranch }}</td>
              <td>{{ i.callnumber }}</td>
              <td>{{ i.barcode }}</td>
            </tr>
          </tbody>
        </table>
        <p v-else><em>No items attached to this record.</em></p>
      </fieldset>
        <h2>Details</h2>
        <fieldset class="rows results">
            <div>
                <ol>
                    <li>
                      <label for="extension">Extension:</label>
                      <input id="extension" v-model.trim="entry.extension" />
                      <div class="hint">Generated DTN from TN and Extensions with _ between each piece</div>
                    </li>
                </ol>
            </div>
          <div>
              <ol>
                <li>
                  <label for="dtn">Digital title number:</label>
                  <input id="dtn" :value="dtn" readonly disabled />
                  <span v-if="dtnStatus === 'checking'" class="hint">Checking…</span>
                  <span v-else-if="dtnStatus === 'taken'" class="fsrm-error text-danger fw-bold">
                    DTN is already in use, must be unique.
                  </span>
                  <span v-else-if="dtnStatus === 'available'" class="fsrm-ok text-success fw-bold"> Available</span>
                  <span v-else-if="dtnStatus === 'error'" class="fsrm-error text-danger fw-bold"> Could not verify</span>
                </li>
                <li>
                  <label for="volume_description">Volume description:</label>
                  <input id="volume_description" v-model.trim="entry.volume_description" />
                </li>
                <li>
                  <label for="owning_institution">Owning institution:</label>
                  <input id="owning_institution" v-model.trim="entry.owning_institution" />
                </li>
                <li>
                  <label for="scan_site">Scan site:</label>
                  <input id="scan_site" v-model.trim="entry.scan_site" />
                </li>
              </ol>
          </div>
        </fieldset>
      <fieldset class="action">
        <button class="btn btn-primary" :disabled="!canSave" @click="save">
          {{ saving ? 'Saving…' : 'Save entry' }}
        </button>
        <span v-if="saved" class="fsrm-saved">Entry {{ saved }} created.</span>
      </fieldset>
    </div>
  </div>
</template>

<script>
const API_BASE = '/api/v1/contrib/fsrecordmetadata';

export default {
  name: 'CreateView',
  data() {
    return {
      searchType: 'biblionumber',
      searchTerm: '',
      record: null,
      selectedItemnumber: null,
      loading: false,
      saving: false,
      saved: null,
      error: null,
      flags: [
        { key: 'md', label: 'MD' },
        { key: 'audit1', label: 'Audit 1' },
        { key: 'audit2', label: 'Audit 2' },
        { key: 'ocr', label: 'OCR' },
        { key: 'published', label: 'Published' },
        { key: 'online_review', label: 'Online review' },
      ],
      entry: this.blankEntry(),
      dtnStatus: 'idle',
      dtnCheckTimer: null,
    };
  },
  computed: {
    selectedItem() {
      if (!this.record) return null;
      return this.record.items.find(i => i.itemnumber === this.selectedItemnumber) || null;
    },
    dtn() {
        if (!this.record) return '';
        return [this.record.biblionumber, this.entry.extension]
        .filter(v => v !== null && v !== undefined && String(v).trim() !== '')
        .join('_');
    },
    canSave() {
        return !!this.record && this.dtnStatus === 'available' && !this.saving;
    },
  },
  watch: {
    dtn: {
      immediate: true,
      handler(value) {
        clearTimeout(this.dtnCheckTimer);
        if (!value) { this.dtnStatus = 'idle'; return; }
        this.dtnStatus = 'checking';
        this.dtnCheckTimer = setTimeout(() => this.checkDtn(value), 300);
      },
    },
  },
  methods: {
    async checkDtn(value) {
        try {
          const res = await fetch(`${API_BASE}/entries/check-dtn?${new URLSearchParams({ dtn: value })}`, {
            headers: { Accept: 'application/json' },
            credentials: 'same-origin',
          });
          if (!res.ok) throw new Error();
          const body = await res.json();
          if (value !== this.dtn) return;          // a newer keystroke superseded this check
          this.dtnStatus = body.available ? 'available' : 'taken';
        } catch (e) {
          if (value === this.dtn) this.dtnStatus = 'error';
        }
    },
    blankEntry() {
      return {
        access: '', problem: '',
        md: false, audit1: false, audit2: false,
        ocr: false, published: false, online_review: false,
      };
    },
    async lookup() {
      this.loading = true;
      this.error = null;
      this.record = null;
      this.saved = null;
      try {
        const params = new URLSearchParams({ [this.searchType]: this.searchTerm });
        const res = await fetch(`${API_BASE}/lookup?${params}`, {
          headers: { Accept: 'application/json' },
          credentials: 'same-origin',
        });
        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `Lookup failed (${res.status})`);
        }
        this.record = await res.json();
        this.selectedItemnumber = this.record.items.length ? this.record.items[0].itemnumber : null;
        this.entry = this.blankEntry();
      } catch (e) {
        this.error = e.message;
      } finally {
        this.loading = false;
      }
    },
    async save() {
      this.saving = true;
      this.error = null;
      this.saved = null;
      try {
        const payload = {
          biblionumber: this.record.biblionumber,
          dtn: this.dtn || null,
          access: this.entry.access || null,
          problem: this.entry.problem || null,
        };
        for (const f of this.flags) payload[f.key] = this.entry[f.key] ? 1 : 0;

        const res = await fetch(`${API_BASE}/entries`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          credentials: 'same-origin',
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `Save failed (${res.status})`);
        }
        const created = await res.json();
        this.saved = created.entry_id;
        this.entry = this.blankEntry();
      } catch (e) {
        this.error = e.message;
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>

<style>
.fsrm-saved { margin-left: 1rem; color: #418940; }
.results {display: grid; grid-template-columns: 1fr 1fr; grid-gap: 2em;}
</style>
