<template>
    <div>
        <form @submit.prevent="save">
            <fieldset class="rows">
                <legend>New entry</legend>
                <ol>
                    <li>
                        <label for="biblionumber" class="required">Title number (biblionumber):</label>
                        <input
                            id="biblionumber"
                            v-model.number="entry.biblionumber"
                            type="text"
                            inputmode="numeric"
                            required
                            @blur="lookupBiblio"
                        />
                        <span v-if="biblio" class="hint">{{ biblio.title }} <template v-if="biblio.author">/ {{ biblio.author }}</template></span>
                        <span v-else-if="biblioError" class="error">{{ biblioError }}</span>
                    </li>
                    <li>
                        <label for="dtn">DTN (digital title number):</label>
                        <input id="dtn" v-model.trim="entry.dtn" type="text" maxlength="255" />
                    </li>
                    <li>
                        <label for="access">Access:</label>
                        <select id="access" v-model="entry.access">
                            <option value="Public">Public</option>
                            <option value="Restricted">Restricted</option>
                            <option value="On-site only">On-site only</option>
                        </select>
                    </li>
                    <li>
                        <label for="problem">Problem:</label>
                        <textarea id="problem" v-model.trim="entry.problem" rows="2" cols="50"></textarea>
                    </li>
                    <li v-for="stage in stages" :key="stage.key">
                        <label :for="stage.key">{{ stage.label }}:</label>
                        <input :id="stage.key" v-model="entry[stage.key]" type="checkbox" :true-value="1" :false-value="0" />
                    </li>
                </ol>
            </fieldset>

            <fieldset class="action">
                <input type="submit" class="btn btn-primary" value="Save" :disabled="saving" />
                <a href="#" class="cancel" @click.prevent="$emit('cancel')">Cancel</a>
            </fieldset>
        </form>
    </div>
</template>

<script>
export default {
    name: "NewEntry",
    emits: ["saved", "cancel"],
    data() {
        return {
            entry: {
                biblionumber: null,
                itemnumber: null,
                dtn: "",
                access: "Public",
                problem: "",
                md: 0,
                audit1: 0,
                audit2: 0,
                ocr: 0,
                published: 0,
                online_review: 0,
            },
            stages: [
                { key: "md", label: "Metadata (MD)" },
                { key: "audit1", label: "Audit 1" },
                { key: "audit2", label: "Audit 2" },
                { key: "ocr", label: "OCR" },
                { key: "published", label: "Published" },
                { key: "online_review", label: "Online review" },
            ],
            biblio: null,
            biblioError: null,
            items: [],
            saving: false,
        };
    },
    methods: {
        async lookupBiblio() {
            this.biblio = null;
            this.biblioError = null;
            this.items = [];
            if (!this.entry.biblionumber) return;
            try {
                const res = await fetch(`/api/v1/biblios/${this.entry.biblionumber}`, {
                    headers: { Accept: "application/json" },
                });
                if (!res.ok) throw new Error(`Biblio ${this.entry.biblionumber} not found`);
                this.biblio = await res.json();

                const itemsRes = await fetch(`/api/v1/biblios/${this.entry.biblionumber}/items`, {
                    headers: { Accept: "application/json" },
                });
                this.items = itemsRes.ok ? await itemsRes.json() : [];
            } catch (e) {
                this.biblioError = e.message;
            }
        },
        async save() {
            if (!this.biblio) {
                await this.lookupBiblio();
                if (!this.biblio) return;
            }
            this.saving = true;
            try {
                const res = await fetch("/api/v1/contrib/fsrecordmetadata/entries", {
                    method: "POST",
                    headers: { "Content-Type": "application/json", Accept: "application/json" },
                    body: JSON.stringify(this.entry),
                });
                if (!res.ok) {
                    const body = await res.json().catch(() => ({}));
                    throw new Error(body.error || `Save failed (${res.status})`);
                }
                this.$emit("saved", await res.json());
            } catch (e) {
                alert(e.message);
            } finally {
                this.saving = false;
            }
        },
    },
};
</script>

<style scoped>
.hint {
    margin-left: 0.5em;
    font-style: italic;
}
.error {
    margin-left: 0.5em;
    color: #c00;
}
</style>
