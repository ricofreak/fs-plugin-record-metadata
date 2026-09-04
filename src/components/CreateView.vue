<template>
  <div>
    <form @submit.prevent="lookup" class="fsrm-search">
      <select v-model="searchType">
        <option value="biblionumber">TN (biblionumber)</option>
        <option value="barcode">Barcode</option>
      </select>
      <input v-model.trim="searchTerm" placeholder="Search for a record" />
      <button
        type="submit"
        class="btn btn-primary"
        :disabled="!searchTerm || loading"
      >
        {{ loading ? "Searching…" : "Find record" }}
      </button>
    </form>

    <p v-if="error" class="fsrm-error">{{ error }}</p>

    <div v-if="record">
      <fieldset class="rows results">
        <div>
          <h3>Bibliographic info.</h3>
          <ol>
            <li><span class="label">Title:</span> {{ record.title }}</li>
            <li><span class="label">Author:</span> {{ record.author }}</li>
            <li>
              <span class="label">Publisher Date:</span>
              {{ record.publication_date }}
            </li>
            <li>
              <span class="label">Language:</span>
              {{ record.lang }}
            </li>
          </ol>
          <table
            class="table table-success table-responsive"
            v-if="record.online_links && record.online_links.length"
          >
            <thead>
              <tr>
                <th>Online link</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(link, idx) in record.online_links" :key="idx">
                <td>
                  <a :href="link.url" target="_blank" rel="noopener">{{
                    link.url
                  }}</a>
                </td>
              </tr>
            </tbody>
          </table>
          <table class="table table-success table-responsive">
            <thead>
              <tr>
                <th>Privacy (998$f)</th>
                <th>Contract (542$r)</th>
                <th>Ex 108 (506$a)</th>
                <th>Copyright (542$l)</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>{{ record.privacy_998f }}</td>
                <td>{{ record.contract_542r }}</td>
                <td>{{ record.ex_108 }}</td>
                <td>{{ record.copyright_542l }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div>
          <h3>Item info.</h3>
          <table
            class="fsrm-items table table-success table-responsive"
            v-if="record.items.length"
          >
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
              >
                <td>{{ i.itemtype }}</td>
                <td>{{ i.branchname || i.homebranch }}</td>
                <td>{{ i.callnumber }}</td>
                <td>{{ i.barcode }}</td>
              </tr>
            </tbody>
          </table>
          <p v-else><em>No items attached to this record.</em></p>
        </div>
      </fieldset>
      <h2>Details</h2>
      <fieldset class="rows results">
        <div>
          <ol>
            <li>
              <label for="extension">Extension:</label>
              <input id="extension" v-model.trim="entry.extension" />
              <div class="hint">
                Generated DTN from TN and Extensions with _ between each piece
              </div>
            </li>
          </ol>
        </div>
        <div>
          <ol>
            <li>
              <label for="dtn">Digital title number:</label>
              <input id="dtn" :value="dtn" readonly disabled />
              <span v-if="dtnStatus === 'checking'" class="hint"
                >Checking…</span
              >
              <span
                v-else-if="dtnStatus === 'taken'"
                class="fsrm-error text-danger fw-bold"
              >
                DTN is already in use, must be unique.
              </span>
              <span
                v-else-if="dtnStatus === 'available'"
                class="fsrm-ok text-success fw-bold"
              >
                Available</span
              >
              <span
                v-else-if="dtnStatus === 'error'"
                class="fsrm-error text-danger fw-bold"
              >
                Could not verify</span
              >
            </li>
            <li>
              <label for="volume_description">Volume description:</label>
              <input
                id="volume_description"
                v-model.trim="entry.volume_description"
              />
            </li>
            <li>
              <label for="owning_institution">Owning institution:</label>
              <AvSelect
                id="owning_institution"
                field="owning_institution"
                v-model="entry.owning_institution"
              />
            </li>
            <li>
              <label for="scan_site">Scan site:</label>
              <AvSelect id="scan_site" field="scan_site" v-model="entry.scan_site" />
            </li>
          </ol>
        </div>
      </fieldset>
      <fieldset class="action">
        <button class="btn btn-primary" :disabled="!canSave" @click="save">
          {{ saving ? "Saving…" : "Save entry" }}
        </button>
        <span v-if="saved" class="fsrm-saved">Entry {{ saved }} created.</span>
      </fieldset>
    </div>
  </div>
</template>

<script>
import { lookupRecord, createEntry, checkDtn as checkDtnApi } from "../api";

export default {
  name: "CreateView",
  data() {
    return {
      searchType: "biblionumber",
      searchTerm: "",
      record: null,
      loading: false,
      saving: false,
      saved: null,
      error: null,
      entry: this.blankEntry(),
      dtnStatus: "idle",
      dtnCheckTimer: null,
    };
  },
  computed: {
    dtn() {
      if (!this.record) return "";
      return [this.record.biblionumber, this.entry.extension]
        .filter((v) => v !== null && v !== undefined && String(v).trim() !== "")
        .join("_");
    },
    canSave() {
      return !!this.record && this.dtnStatus === "available" && !this.saving;
    },
  },
  watch: {
    dtn: {
      immediate: true,
      handler(value) {
        clearTimeout(this.dtnCheckTimer);
        if (!value) {
          this.dtnStatus = "idle";
          return;
        }
        this.dtnStatus = "checking";
        this.dtnCheckTimer = setTimeout(() => this.checkDtn(value), 300);
      },
    },
  },
  methods: {
    async checkDtn(value) {
      try {
        const body = await checkDtnApi(value);
        if (value !== this.dtn) return;
        this.dtnStatus = body.available ? 'available' : 'taken';
      } catch (e) {
        if (value === this.dtn) this.dtnStatus = 'error';
      }
    },
    blankEntry() {
      return {
        extension: "",
        volume_description: "",
        owning_institution: "",
        scan_site: "",
      };
    },
    async lookup() {
      this.loading = true;
      this.error = null;
      this.record = null;
      this.saved = null;
      try {
        this.record = await lookupRecord({ [this.searchType]: this.searchTerm });
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
          itemnumber: this.record.itemnumber || null,
          dtn: this.dtn || null,
          owning_institution: this.entry.owning_institution || null,
          volume_description: this.entry.volume_description || null,
          scan_site: this.entry.scan_site || null,
        };

        const created = await createEntry(payload);
        this.saved = created.entry_id;
        this.entry = this.blankEntry();
      } catch (e) {
        if (e.status === 409) this.dtnStatus = "taken";
        this.error = e.message;
      } finally {
        this.saving = false;
      }
    },
  },
};
</script>

<style>
.fsrm-saved {
  margin-left: 1rem;
  color: #418940;
}
.results {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-gap: 2em;
}
</style>
