<template>

  <div>
    <form @submit.prevent="search" class="fsrm-search">
      <select v-model="searchType">
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" placeholder="Find an entry" />
      <button
        type="submit"
        class="btn btn-primary"
        :disabled="!searchTerm || loading"
      >
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
            <td>
              <input
                type="radio"
                :value="e.entry_id"
                :checked="selected && selected.entry_id === e.entry_id"
              />
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
      <h2>DTN: {{ selected.dtn }}</h2>

      <fieldset class="rows">
        <ol>
          <li><span class="label">Title:</span> {{ selected.title }}</li>
          <li><span class="label">Author:</span> {{ selected.author }}</li>
          <li><span class="label">Barcodes:</span> {{ selected.barcodes }}</li>
          <li><span class="label">Call #:</span> {{ selected.callnumbers }}</li>
        </ol>
      </fieldset>

      <fieldset id="scanform_step1" class="rows">
        <ol>
          <li>
            <label for="dtn">Digital title number:</label>
            <input id="dtn" :value="selected.dtn" readonly disabled />
          </li>
          <li>
            <label for="tn">Title number:</label>
            <input id="tn" :value="selected.biblionumber" readonly disabled />
          </li>
          <li>
            <label for="secondary_identifier">Secondary identifier:</label>
            <input
              id="secondary_identifier"
              v-model.trim="form.secondary_identifier"
            />
          </li>
          <li>
            <label for="volume_description">Volume description:</label>
            <input
              id="volume_description"
              v-model.trim="form.volume_description"
            />
          </li>
          <li>
            <label>Problem number(s):</label>
            <span v-if="!problemList.length">None</span>
            <span v-else>
              <span v-for="(p, idx) in problemList" :key="p.id">
                <a href="#"
                :class="p.open ? 'fsrm-problem-open' : 'fsrm-problem-closed'"
                @click.prevent="editProblem(p.id)"
              >{{ p.id }}</a><span v-if="idx < problemList.length - 1">, </span></span>
            </span>
          </li>
          <li>
            <label for="add_problem">Add problems:</label>
            <button type="button" id="add_problem" @click="addProblem">+ Add</button>
          </li>
          <li>
            <label for="owning_institution">Owning Institution:</label>
            <input
              id="owning_institution"
              v-model.trim="form.owning_institution"
            />
          </li>
          <li>
            <label for="access">Access level:</label>
            <input id="access" v-model.trim="form.access" />
          </li>
          <li>
            <label for="itypes">Item type(s):</label>
            <input id="itypes" :value="selected.itypes" readonly disabled />
          </li>
          <li>
            <label for="barcodes">Barcode(s):</label>
            <input id="barcodes" :value="selected.barcodes" readonly disabled />
          </li>
          <li>
            <label for="callnumbers">Call number(s):</label>
            <input
              id="callnumbers"
              :value="selected.callnumbers"
              readonly
              disabled
            />
          </li>
          <li>
            <label for="number_of_pages">Number of pages:</label>
            <input id="number_of_pages" v-model.trim="form.number_of_pages" />
          </li>
          <li style="margin-top: 1em">
            <label for="url_856x">URL:</label>
            <input id="url_856x" />
          </li>
          <li>
            <label for="limb_id">Limb ID:</label>
            <input id="limb_id" />
          </li>
        </ol>

        <ol>
          <li>
            <label for="md_date">Metadata complete date:</label>
            <input
              id="md_date"
              type="date"
              v-model.trim="form.md_date"
              @focus="setToday('md_date')"
            />
            <a type="button" class="clear_date fa fa-fw fa-times" aria-hidden="true" aria-label="Clear date" @click="clearDate('md_date')"></a>
          </li>
          <li>
            <label for="scan_site">Scan site:</label>
            <input id="scan_site" v-model.trim="form.scan_site" />
          </li>
          <li>
            <label for="scan_operator_by">Scan operator:</label>
            <input id="scan_operator_by" v-model.trim="form.scan_operator_by" />
            <a type="button" class="pick_me fa fa-fw fa-hand" aria-hidden="true" aria-label="Set Scan operator to current user" @click="setMe('scan_operator_by')"></a>
            <span v-if="names.scan_operator_by" class="hint">{{ names.scan_operator_by }}</span>
          </li>
          <li>
            <label for="scan_machine">Scan machine #:</label>
            <input id="scan_machine" v-model.trim="form.scan_machine" />
          </li>
          <li>
            <label for="scan_date">Scan date:</label>
            <input
              id="scan_date"
              type="date"
              v-model.trim="form.scan_date"
              @focus="setToday('scan_date')"
            />
          </li>
          <li>
            <label for="scan_site_notes">Scan site notes:</label>
            <textarea
              id="scan_site_notes"
              v-model.trim="form.scan_site_notes"
            ></textarea>
          </li>
          <li>
            <label for="scanned_image_count">Scanned images count:</label>
            <input
              id="scanned_image_count"
              v-model.trim="form.scanned_image_count"
            />
          </li>
          <li style="margin-top: 1em">
            <label for="image_auditor_1_by">Image auditor 1:</label>
            <input
              id="image_auditor_1_by"
              v-model.trim="form.image_auditor_1_by"
            />
          </li>
          <li>
            <label for="audit_date_1">Audit 1 date:</label>
            <input
              id="audit_date_1"
              type="date"
              v-model.trim="form.audit_date_1"
              @focus="setToday('audit_date_1')"
            />
          </li>
          <li>
            <label for="image_auditor_2_by">Image auditor 2:</label>
            <input
              id="image_auditor_2_by"
              v-model.trim="form.image_auditor_2_by"
            />
          </li>
          <li>
            <label for="audit_date_2">Audit 2 date:</label>
            <input
              id="audit_date_2"
              type="date"
              v-model.trim="form.audit_date_2"
              @focus="setToday('audit_date_2')"
            />
          </li>
          <li style="margin-top: 1em">
            <label for="images_sent_by">Image sent by:</label>
            <input id="images_sent_by" v-model.trim="form.images_sent_by" />
          </li>
          <li>
            <label for="images_sent_date">Image sent date:</label>
            <input
              id="images_sent_date"
              type="date"
              v-model.trim="form.images_sent_date"
              @focus="setToday('images_sent_date')"
            />
          </li>
        </ol>
      </fieldset>

      <fieldset class="action">
        <div class="btn-toolbar">
        <button class="btn btn-primary" :disabled="saving" @click="save">
          {{ saving ? "Saving…" : "Save" }}
        </button>
          <button class="btn btn-primary" type="button" @click="saveAndGo" :disabled="saving">
            {{ saving ? "Saving…" : "Save and continue to step 2" }}
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
import ProblemsModal from './ProblemsModal.vue';

const API_BASE = "/api/v1/contrib/fsrecordmetadata";

export default {
  name: "ScanningViewOne",
  props: {
    entry: { type: Object, default: null },
  },
  components: { ProblemsModal },
  data() {
    return {
      searchType: "biblionumber",
      searchTerm: "",
      entries: [],
      selected: null,
      form: {},
      searched: false,
      loading: false,
      saving: false,
      savedAt: null,
      error: null,
      showProblemsModal: false,
      names: {},
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
  computed: {
    problemList() {
      if (!this.selected || !this.selected.problem_numbers) return [];
      return this.selected.problem_numbers.split(',').map((chunk) => {
        const [id, open] = chunk.split(':');
        return { id, open: open === '1' };
      });
    },
  },
  methods: {
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
      await this.search(); // update on save
      const again = this.entries.find((e) => e.entry_id === entryId);
      if (again) this.select(again);
    },
    setToday(field) {
      if (this.form[field]) return; // if we already have a date, bail
      const d = new Date();
      const iso = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
        .toISOString()
        .slice(0, 10);
      this.form[field] = iso;
    },
    setMe(field) {
      const u = window.fsrmUser || {};
      if (!u.borrowernumber) return;
      this.form[field] = u.borrowernumber;
      this.names[field] = u.name;
    },
    async search() {
      this.loading = true;
      this.error = null;
      this.entries = [];
      this.selected = null;
      this.savedAt = null;
      try {
        const params = new URLSearchParams({
          [this.searchType]: this.searchTerm,
        });
        const res = await fetch(`${API_BASE}/entries?${params}`, {
          headers: { Accept: "application/json" },
          credentials: "same-origin",
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
      this.names = {};
      this.form = {
        secondary_identifier: entry.secondary_identifier || "",
        volume_description: entry.volume_description || "",
        owning_institution: entry.owning_institution || "",
        access: entry.access || "",
        number_of_pages: entry.number_of_pages || "",

        md_date: entry.md_date || "",
        md_by: entry.md_by || "",

        scan_site: entry.scan_site || "",
        scan_operator_by: entry.scan_operator_by || "",
        scan_machine: entry.scan_machine || "",
        scan_date: entry.scan_date || "",
        scan_site_notes: entry.scan_site_notes || "",
        scanned_image_count: entry.scanned_image_count || "",

        image_auditor_1_by: entry.image_auditor_1_by || "",
        audit_date_1: entry.audit_date_1 || "",
        image_auditor_2_by: entry.image_auditor_2_by || "",
        audit_date_2: entry.audit_date_2 || "",

        images_sent_by: entry.images_sent_by || "",
        images_sent_date: entry.images_sent_date || "",
      };
    },
    async save() {
      this.saving = true;
      this.error = null;
      this.savedAt = null;
      try {
        const payload = {
          secondary_identifier: this.form.secondary_identifier || null,
          owning_institution: this.form.owning_institution || null,
          volume_description: this.form.volume_description || null,
          access: this.form.access || null,
          number_of_pages: this.form.number_of_pages || null,

          md_date: this.form.md_date || null,
          md_by: this.form.md_by || null,

          scan_site: this.form.scan_site || null,
          scan_operator_by: this.form.scan_operator_by || null,
          scan_machine: this.form.scan_machine || null,
          scan_date: this.form.scan_date || null,
          scan_site_notes: this.form.scan_site_notes || null,
          scanned_image_count: this.form.scanned_image_count || null,

          image_auditor_1_by: this.form.image_auditor_1_by || null,
          audit_date_1: this.form.audit_date_1 || null,
          image_auditor_2_by: this.form.image_auditor_2_by || null,
          audit_date_2: this.form.audit_date_2 || null,

          images_sent_by: this.form.images_sent_by || null,
          images_sent_date: this.form.images_sent_date || null,
        };
        console.log("PUT", this.selected.entry_id, JSON.stringify(payload));
        const res = await fetch(
          `${API_BASE}/entries/${this.selected.entry_id}`,
          {
            method: "PUT",
            headers: {
              "Content-Type": "application/json",
              Accept: "application/json",
            },
            credentials: "same-origin",
            body: JSON.stringify(payload),
          },
        );
        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `Save failed (${res.status})`);
        }
        const updated = await res.json();
        const idx = this.entries.findIndex(
          (e) => e.entry_id === updated.entry_id,
        );
        if (idx !== -1) this.entries.splice(idx, 1, updated);
        this.selected = updated;
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
      this.$emit("saved", updated);   // Main sets this.entry = updated
      this.$emit("step", 2);
    },
    clearDate(field) {
      this.form[field] = "";
      this.names[field] = "";
    },
  },
};
</script>
<style>
#scanform_step1 {
  display: grid;
  grid-template-columns: 1fr 1fr;
}
.fsrm-problem-open   { color: #c00; font-weight: bold; }
.fsrm-problem-closed { color: #418940; font-weight: bold; }
</style>
