<template>
  <div>
    <h2>Roles</h2>
    <p>
      Enter borrowernumbers separated by commas or spaces. Anyone not listed
      here has read-only access to the plugin.
    </p>

    <p v-if="error" class="fsrm-error">{{ error }}</p>
    <p v-if="savedAt" class="fsrm-saved">Roles saved.</p>

    <fieldset class="rows">
      <ol>
        <li v-for="role in roles" :key="role.id">
          <label :for="'role_' + role.id">{{ role.label }}:</label>
          <textarea
            :id="'role_' + role.id"
            v-model="values[role.id]"
            rows="3"
            cols="60"
          ></textarea>
          <div class="hint">{{ role.hint }}</div>
        </li>
      </ol>
    </fieldset>

    <fieldset class="action">
      <button
        class="btn btn-primary"
        type="button"
        :disabled="saving || loading"
        @click="save"
      >
        {{ saving ? "Saving…" : "Save roles" }}
      </button>
    </fieldset>
  </div>
</template>

<script>
import { getUsers, saveUsers } from "../api";

const ROLES = [
  { id: "admin", label: "Admin", hint: "Access to all functions" },
  { id: "metadata", label: "Metadata", hint: "Search, add entry, bulk add, scanning" },
  { id: "scanning", label: "Scanning", hint: "Search, scanning, problems, reports" },
  { id: "processing", label: "Processing", hint: "Search, processing, problems, reports" },
  { id: "readonly", label: "Read-only", hint: "View only" },
];

export default {
  name: "AdminView",
  data() {
    return {
      roles: ROLES,
      values: Object.fromEntries(ROLES.map((r) => [r.id, ""])),
      loading: false,
      saving: false,
      savedAt: null,
      error: null,
    };
  },
  async created() {
    this.loading = true;
    try {
      const body = await getUsers();
      for (const role of ROLES) {
        this.values[role.id] = (body[role.id] || []).join(", ");
      }
    } catch (e) {
      this.error = e.message;
    } finally {
      this.loading = false;
    }
  },
  methods: {
    async save() {
      this.saving = true;
      this.error = null;
      this.savedAt = null;
      try {
        const payload = {};
        for (const role of ROLES) {
          payload[role.id] = (this.values[role.id] || "")
            .split(/[\s,]+/)
            .map((s) => s.trim())
            .filter(Boolean);
        }

        await saveUsers(payload);
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
