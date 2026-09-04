<template>
  <div>
  <div class="modal-backdrop fade show"></div>
  <div class="modal fade show block modal-xl" data-bs-backdrop="static" data-bs-keyboard="false" style="display: block;">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">{{ isEdit ? 'Edit problem ' + problemId : 'Add problem' }} — {{ dtn }}</h5>
          <button type="button" class="btn-close" @click="$emit('cancel')"></button>
        </div>

        <div class="modal-body">
          <p v-if="error" class="fsrm-error">{{ error }}</p>

          <div class="fsrm-problem-grid">
            <fieldset class="rows">
              <ol>
                <li>
                  <label for="p_status">Status:</label>
                  <AvSelect id="p_status" field="problem_status" v-model="form.status" />
                </li>
                <li>
                  <label for="p_problem_type">Problem type:</label>
                  <AvSelect id="p_problem_type" field="problem_type" v-model="form.problem_type" />
                </li>
                <li>
                  <label for="p_problem_description">Problem description:</label>
                  <textarea id="p_problem_description" v-model.trim="form.problem_description" rows="3"></textarea>
                </li>
                <li>
                  <label for="p_reported_by">Reported by:</label>
                  <StaffPicker id="p_reported_by" label="Reported by" v-model="form.reported_by" v-model:displayName="names.reported_by" />
                </li>
                <li>
                  <label for="p_problem_date">Problem date:</label>
                  <DateField id="p_problem_date" label="Problem date" v-model="form.problem_date" />
                </li>
              </ol>
            </fieldset>

            <fieldset class="rows">
              <ol>
                <li>
                  <label for="p_solution_owner">Solution owner:</label>
                  <StaffPicker id="p_solution_owner" label="Solution owner" v-model="form.solution_owner" v-model:displayName="names.solution_owner" />
                </li>
                <li>
                  <label for="p_solution">Solution:</label>
                  <textarea id="p_solution" v-model.trim="form.solution" rows="3"></textarea>
                </li>
                <li>
                  <label for="p_solution_date">Solution date:</label>
                  <DateField id="p_solution_date" label="Solution date" v-model="form.solution_date" />
                </li>
                <li>
                  <label for="p_fixed_by">Fixed by:</label>
                  <StaffPicker id="p_fixed_by" label="Fixed by" v-model="form.fixed_by" v-model:displayName="names.fixed_by" />
                </li>
              </ol>
            </fieldset>
          </div>
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
  </div>
</template>

<script>
import { getProblems, createProblem, updateProblem } from "../api";

const blankForm = () => ({
  status: "",
  problem_type: "",
  problem_description: "",
  reported_by: null,
  problem_date: "",
  solution_owner: null,
  solution: "",
  solution_date: "",
  fixed_by: null,
});

export default {
  name: "ProblemsModal",
  props: {
    entryId: { type: Number, required: true },
    problemId: { type: Number, default: null },
    dtn: { type: String, default: "" },
  },
  emits: ["saved", "cancel"],
  data() {
    return {
      saving: false,
      error: null,
      form: blankForm(),
      names: {},
    };
  },
  computed: {
    isEdit() {
      return this.problemId !== null;
    },
  },
  async created() {
    if (!this.isEdit) return;
    try {
      const rows = await getProblems({ problem_id: this.problemId });
      if (!rows.length) return;
      const p = rows[0];
      const form = blankForm();
      for (const key of Object.keys(form)) {
        form[key] = p[key] === null || p[key] === undefined ? form[key] : p[key];
      }
      this.form = form;
    } catch (e) {
      this.error = e.message;
    }
  },
  methods: {
    async save() {
      this.saving = true;
      this.error = null;
      try {
        const payload = {};
        for (const [k, v] of Object.entries(this.form)) {
          payload[k] = v === "" ? null : v;
        }

        let result;
        if (this.isEdit) {
          result = await updateProblem(this.problemId, payload);
        } else {
          payload.entry_id = this.entryId;
          result = await createProblem(payload);
        }

        this.$emit("saved", result);
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
.fsrm-problem-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

@media (max-width: 800px) {
  .fsrm-problem-grid {
    grid-template-columns: 1fr;
  }
}
</style>
