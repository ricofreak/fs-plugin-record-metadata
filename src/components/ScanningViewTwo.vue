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

      <fieldset id="scanform_step2" class="rows">
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
                <span
                  v-for="(p, idx) in problemList"
                  :key="p.id"
                  :class="p.open ? 'fsrm-problem-open' : 'fsrm-problem-closed'"
                >{{ p.id }}<span v-if="idx < problemList.length - 1">, </span></span>
              </span>
          </li>
          <li>
            <label for="add_problem">Add problems:</label>
            <button id="add_problem">+ Add</button>
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
            <label for="ocr_site">OCR site:</label>
            <input id="ocr_site" v-model.trim="form.ocr_site" />
          </li>
          <li>
            <label for="ocr_date">OCR date:</label>
            <input id="ocr_date" type="date" v-model.trim="form.ocr_date" @focus="setToday('ocr_date')" />
          </li>
          <li>
            <label for="pdf_ready_for_review">PDF ready for review:</label>
            <input id="pdf_ready_for_review" v-model.trim="form.pdf_ready_for_review" />
          </li>
          <li>
            <label for="review_by">Published image review by:</label>
            <input id="review_by" type="date" v-model.trim="form.review_by" @focus="setToday('review_by')" />
          </li>
          <li>
            <label for="review_start_date">Review start date:</label>
            <input id="review_start_date" type="date" v-model.trim="form.review_start_date" @focus="setToday('review_start_date')" />
          </li>
          <li>
            <label for="review_complete_date">Review complete date:</label>
            <input id="review_complete_date" type="date" v-model.trim="form.review_complete_date" @focus="setToday('review_complete_date')" />
          </li>
          <li>
            <label for="image_review_notes">Image review notes:</label>
            <textarea id="image_review_notes" v-model.trim="form.image_review_notes"></textarea>
          </li>
          <li>
            <label for="pdf_sent_to">PDF sent to:</label>
            <input id="pdf_sent_to" v-model.trim="form.pdf_sent_to" />
          </li>
          <li>
            <label for="pdf_loaded_date">PDF loaded date:</label>
            <input id="pdf_loaded_date" type="date" v-model.trim="form.pdf_loaded_date" @focus="setToday('pdf_loaded_date')" />
          </li>
          <li>
            <label for="pages_online">Loaded pages #:</label>
            <textarea id="pages_online" v-model.trim="form.pages_online"></textarea>
          </li>
        </ol>
        <ol>
          <li>
            <label for="pdf_orem_archived_date">PDF Orem archive date:</label>
            <input id="pdf_orem_archived_date" type="date" v-model.trim="form.pdf_orem_archived_date" @focus="setToday('pdf_orem_archived_date')" />
          </li>
          <li>
            <label for="pdf_orem_drive_name">PDF Orem drive name:</label>
            <input id="pdf_orem_drive_name" v-model.trim="form.pdf_orem_drive_name" />
          </li>
          <li>
            <label for="pdf_copy2_archived_date">PDF Copy2 archive date:</label>
            <input id="pdf_copy2_archived_date" type="date" v-model.trim="form.pdf_copy2_archived_date" @focus="setToday('pdf_copy2_archived_date')" />
          </li>
          <li>
            <label for="pdf_copy2_drive_name">PDF Copy2 drive name:</label>
            <input id="pdf_copy2_drive_name" v-model.trim="form.pdf_copy2_drive_name" />
          </li>
          <li>
            <label for="tiff_orem_archived_date">TIFF Orem archive date:</label>
            <input id="tiff_orem_archived_date" type="date" v-model.trim="form.tiff_orem_archived_date" @focus="setToday('tiff_orem_archived_date')" />
          </li>
          <li>
            <label for="tiff_orem_drive_name">TIFF Orem drive name:</label>
            <input id="tiff_orem_drive_name" v-model.trim="form.tiff_orem_drive_name" />
          </li>
          <li>
            <label for="tiff_copy2_archived_date">TIFF Copy2 archive date:</label>
            <input id="tiff_copy2_archived_date" type="date" v-model.trim="form.tiff_copy2_archived_date" @focus="setToday('tiff_copy2_archived_date')" />
          </li>
          <li>
            <label for="tiff_copy2_drive_name">TIFF Copy2 drive name:</label>
            <input id="tiff_copy2_drive_name" v-model.trim="form.tiff_copy2_drive_name" />
          </li>
          <li>
            <label for="images_removed_by">Image removal request by:</label>
            <input id="images_removed_by" v-model.trim="form.images_removed_by"  />
          </li>
          <li>
            <label for="images_removed_date">Image removal date:</label>
            <input id="images_removed_date" type="date" v-model.trim="form.images_removed_date" @focus="setToday('images_removed_date')" />
          </li>
          <li>
            <label for="images_removed_notes">Image removal notes:</label>
            <textarea id="images_removed_notes" v-model.trim="form.images_removed_notes"></textarea>
          </li>
        </ol>

      </fieldset>

      <fieldset class="action">
        <button class="btn btn-primary" :disabled="saving" @click="save">
          {{ saving ? "Saving…" : "Save" }}
        </button>
        <span v-if="savedAt" class="fsrm-saved">Saved.</span>
        <button class="btn btn-primary" type="button" @click="saveAndBack" :disabled="saving">
            {{ saving ? "Saving…" : "Save and back to step 1" }}
        </button>
      </fieldset>
    </div>
  </div>
</template>

<script>
const API_BASE = "/api/v1/contrib/fsrecordmetadata";

const toDateInput = (v) => (v ? String(v).slice(0, 10) : "");

export default {
  name: "ScanningViewTwo",
  props: {
    entry: { type: Object, default: null },
  },
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
    setToday(field) {
      if (this.form[field]) return; // if we already have a date, bail
      const d = new Date();
      const iso = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
        .toISOString()
        .slice(0, 10);
      this.form[field] = iso;
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
      this.form = {
        secondary_identifier: entry.secondary_identifier || "",
        volume_description: entry.volume_description || "",
        owning_institution: entry.owning_institution || "",
        access: entry.access || "",
        number_of_pages: entry.number_of_pages || "",

        ocr_site: entry.ocr_site || "",
        ocr_date: toDateInput(entry.ocr_date),
        pdf_ready_for_review: entry.pdf_ready_for_review || "",
        review_by: toDateInput(entry.review_by),
        review_start_date: toDateInput(entry.review_start_date),
        review_complete_date: toDateInput(entry.review_complete_date),
        image_review_notes: entry.image_review_notes || "",
        pdf_sent_to: entry.pdf_sent_to || "",
        pdf_loaded_date: toDateInput(entry.pdf_loaded_date),
        pages_online: entry.pages_online || "",

        pdf_orem_archived_date: toDateInput(entry.pdf_orem_archived_date),
        pdf_orem_drive_name: entry.pdf_orem_drive_name || "",
        pdf_copy2_archived_date: toDateInput(entry.pdf_copy2_archived_date),
        pdf_copy2_drive_name: entry.pdf_copy2_drive_name || "",
        tiff_orem_archived_date: toDateInput(entry.tiff_orem_archived_date),
        tiff_orem_drive_name: entry.tiff_orem_drive_name || "",
        tiff_copy2_archived_date: toDateInput(entry.tiff_copy2_archived_date),
        tiff_copy2_drive_name: entry.tiff_copy2_drive_name || "",

        images_removed_by: entry.images_removed_by || "",
        images_removed_date: toDateInput(entry.images_removed_date),
        images_removed_notes: entry.images_removed_notes || "",
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

          ocr_site: this.form.ocr_site || null,
          ocr_date: this.form.ocr_date || null,
          pdf_ready_for_review: this.form.pdf_ready_for_review || null,
          review_by: this.form.review_by || null,
          review_start_date: this.form.review_start_date || null,
          review_complete_date: this.form.review_complete_date || null,
          image_review_notes: this.form.image_review_notes || null,
          pdf_sent_to: this.form.pdf_sent_to || null,
          pdf_loaded_date: this.form.pdf_loaded_date || null,
          pages_online: this.form.pages_online || null,

          pdf_orem_archived_date: this.form.pdf_orem_archived_date || null,
          pdf_orem_drive_name: this.form.pdf_orem_drive_name || null,
          pdf_copy2_archived_date: this.form.pdf_copy2_archived_date || null,
          pdf_copy2_drive_name: this.form.pdf_copy2_drive_name || null,
          tiff_orem_archived_date: this.form.tiff_orem_archived_date || null,
          tiff_orem_drive_name: this.form.tiff_orem_drive_name || null,
          tiff_copy2_archived_date: this.form.tiff_copy2_archived_date || null,
          tiff_copy2_drive_name: this.form.tiff_copy2_drive_name || null,

          images_removed_by: this.form.images_removed_by || null,
          images_removed_date: this.form.images_removed_date || null,
          images_removed_notes: this.form.images_removed_notes || null,

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
    async saveAndBack() {
      console.log("WE HERE");
      const updated = await this.save();
      if (!updated) return;
      this.$emit("saved", updated);   // Main sets this.entry = updated
      this.$emit("step", 1);
    },
  },
};
</script>
<style>
#scanform_step2 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
}
.fsrm-problem-open   { color: #c00; font-weight: bold; }
.fsrm-problem-closed { color: #418940; font-weight: bold; }
</style>
