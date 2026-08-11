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
            </ol>
          </fieldset>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-default" @click="$emit('cancel')">Cancel</button>
          <button type="button" class="btn btn-primary" :disabled="saving" @click="save">
            {{ saving ? 'Saving…' : 'Add problem' }}
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
    dtn: { type: String, default: '' },
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
    async save() {
      this.saving = true;
      this.error = null;
      try {
        const payload = { entry_id: this.entryId };
        for (const [k, v] of Object.entries(this.form)) {
          payload[k] = v === '' ? null : v;
        }

        const res = await fetch(`${API_BASE}/problems`, {
          method: 'POST',
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
