<template>
  <div class="modal fade show fsrm-modal-backdrop" style="display: block;" @click.self="$emit('cancel')">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Add problem — {{ dtn }}</h5>
          <button type="button" class="btn-close" @click="$emit('cancel')"></button>
        </div>

        <div class="modal-body">
          <p v-if="error" class="fsrm-error">{{ error }}</p>

          <fieldset class="rows">
            <ol>
              <li>
                <label for="p_step">Step:</label>
                <input id="p_step" v-model.trim="form.step" />
              </li>
              <li>
                <label for="p_status">Status:</label>
                <input id="p_status" v-model.trim="form.status" />
              </li>
              <li>
                <label for="p_reason">Reason:</label>
                <input id="p_reason" v-model.trim="form.reason" />
              </li>
              <li>
                <label for="p_description">Description:</label>
                <textarea id="p_description" v-model.trim="form.description" rows="3"></textarea>
              </li>
              <li>
                <label for="p_problem_date">Problem date:</label>
                <input id="p_problem_date" type="date" v-model="form.problem_date" />
              </li>
              <li>
                <label for="p_initials">Initials:</label>
                <input id="p_initials" v-model.trim="form.initials" />
              </li>
              <li v-if="isEdit">
                <label for="p_resolved_on">Resolved on:</label>
                <input id="p_resolved_on" type="date" v-model="form.resolved_on" />
                <button type="button" class="btn btn-link btn-sm" @click="resolveToday">Close problem</button>
              </li>
            </ol>
          </fieldset>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-default" @click="$emit('cancel')">Cancel</button>
          <button type="button" class="btn btn-primary" :disabled="saving" @click="save">
            {{ saving ? 'Saving…' : (isEdit ? 'Save changes' : 'Add problem') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
const API_BASE = '/api/v1/contrib/fsrecordmetadata';

export default {
  name: 'ProblemModal',
  props: {
    entryId: { type: Number, required: true },
    problemId: { type: Number, default: null },
    dtn: { type: String, default: '' },
  },
  computed: {
    isEdit() { return this.problemId !== null; },
  },
  async created() {
    if (!this.isEdit) return;
    const res = await fetch(`${API_BASE}/problems?problem_id=${this.problemId}`, {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });
    if (res.ok) {
      const rows = await res.json();
      if (rows.length) {
        const p = rows[0];
        this.form = {
          step: p.step || '',
          status: p.status || '',
          reason: p.reason || '',
          description: p.description || '',
          problem_date: p.problem_date || '',
          initials: p.initials || '',
          resolved_on: p.resolved_on || '',
        };
      }
    }
  },
  emits: ['saved', 'cancel'],
  data() {
    return {
      saving: false,
      error: null,
      form: {
        step: '',
        status: 'Open',
        reason: '',
        description: '',
        problem_date: new Date(Date.now() - new Date().getTimezoneOffset() * 60000)
          .toISOString()
          .slice(0, 10),
        initials: '',
      },
    };
  },
  methods: {
    resolveToday() {
      const d = new Date();
      this.form.resolved_on = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
        .toISOString().slice(0, 10);
    },
    async save() {
      this.saving = true;
      this.error = null;
      try {
        const url = this.isEdit ? `${API_BASE}/problems/${this.problemId}` : `${API_BASE}/problems`;
        const method = this.isEdit ? 'PUT' : 'POST';

        const payload = {};
        for (const [k, v] of Object.entries(this.form)) payload[k] = v === '' ? null : v;
        if (!this.isEdit) {
          payload.entry_id = this.entryId;
          delete payload.resolved_on;
        }

        const res = await fetch(url, {
          method,
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          credentials: 'same-origin',
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const body = await res.json().catch(() => ({}));
          throw new Error(body.error || `Save failed (${res.status})`);
        }
        this.$emit('saved', await res.json());
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
.fsrm-modal-backdrop {
  background: rgba(0, 0, 0, .5);
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 1050;
  overflow-y: auto;
}
</style>
