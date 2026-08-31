<template>
  <ScanningForm
    :entry="entry"
    :field-keys="fieldKeys"
    :next-step="2"
    next-step-label="Save and continue to step 2"
    @saved="$emit('saved', $event)"
    @step="$emit('step', $event)"
  >
  <template #fields="{ form, names, selected, editProblem, addProblem }">

      <fieldset  class="rows">
        <div id="scanform_step1">
            <ol>
              <AccessLevel :value="selected.access" :source="selected.access_source" />
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
                <input id="secondary_identifier" v-model.trim="form.secondary_identifier" />
              </li>
              <li>
                <label for="volume_description">Volume description:</label>
                <input id="volume_description" v-model.trim="form.volume_description" />
              </li>
              <li>
                <label>Problem number(s):</label>
                <ProblemNumbers :value="selected.problem_numbers" @edit="editProblem" />
              </li>
              <li>
                <label for="add_problem">Add problems:</label>
                <button type="button" id="add_problem" @click="addProblem">+ Add</button>
              </li>
              <li>
                <label for="owning_institution">Owning institution:</label>
                <AvSelect id="owning_institution" field="owning_institution" v-model="form.owning_institution" />
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
                <input id="callnumbers" :value="selected.callnumbers" readonly disabled />
              </li>
              <li>
                <label for="number_of_pages">Number of pages:</label>
                <input type="number" id="number_of_pages" v-model.trim="form.number_of_pages" />
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
                <DateField id="md_date" label="Metadata complete date" v-model="form.md_date" />
              </li>
              <li>
                <label for="scan_site">Scan site:</label>
                <AvSelect id="scan_site" field="scan_site" v-model="form.scan_site" />
              </li>
              <li>
                <label for="scan_operator_by">Scan operator:</label>
                <StaffPicker id="scan_operator_by" label="Scan operator" v-model="form.scan_operator_by" v-model:displayName="names.scan_operator_by" />
              </li>
              <li>
                <label for="scan_machine">Scan machine #:</label>
                <AvSelect id="scan_machine" field="scan_machine" v-model="form.scan_machine" />
              </li>
              <li>
                <label for="scan_date">Scan date:</label>
                    <DateField id="scan_date" label="Scan date" v-model="form.scan_date" />
              </li>
              <li>
                <label for="scan_site_notes">Scan site notes:</label>
                <textarea id="scan_site_notes" v-model.trim="form.scan_site_notes"></textarea>
              </li>
              <li>
                <label for="scanned_image_count">Scanned images count:</label>
                <input type="number" id="scanned_image_count" v-model.trim="form.scanned_image_count" />
              </li>
              <li style="margin-top: 1em">
                <label for="image_auditor_1_by">Image auditor 1:</label>
                <StaffPicker id="image_auditor_1_by" label="Image auditor 1" v-model="form.image_auditor_1_by" v-model:displayName="names.image_auditor_1_by" />
              </li>
              <li>
                <label for="audit_date_1">Audit 1 date:</label>
                <DateField id="audit_date_1" label="Audit 1 date" v-model="form.audit_date_1" />
              </li>
              <li>
                <label for="image_auditor_2_by">Image auditor 2:</label>
                <StaffPicker id="image_auditor_2_by" label="Image auditor 2" v-model="form.image_auditor_2_by" v-model:displayName="names.image_auditor_2_by" />
              </li>
              <li>
                <label for="audit_date_2">Audit 2 date:</label>
                <DateField id="audit_date_2" label="Audit 2 date" v-model="form.audit_date_2" />
              </li>
              <li style="margin-top: 1em">
                <label for="images_sent_by">Image sent by:</label>
                <StaffPicker id="images_sent_by" label="Image sent by" v-model="form.images_sent_by" v-model:displayName="names.images_sent_by" />
              </li>
              <li>
                <label for="images_sent_date">Image sent date:</label>
                <DateField id="images_sent_date" label="Image sent date" v-model="form.images_sent_date" />
              </li>
            </ol>
        </div>
      </fieldset>
    </template>
  </ScanningForm>
</template>

<script>
import ScanningForm from "./ScanningForm.vue";
import ProblemNumbers from "./ProblemNumbers.vue";

import DateField from "./DateField.vue";
import StaffPicker from "./StaffPicker.vue";

export default {
  name: "ScanningViewOne",
  components: { ScanningForm, ProblemNumbers, DateField, StaffPicker },
  props: { entry: { type: Object, default: null } },
  emits: ["saved", "step"],
  data() {
    return {
      fieldKeys: [
        "secondary_identifier",
        "owning_institution",
        "volume_description",
        "number_of_pages",
        "md_date",
        "md_by",
        "scan_site",
        "scan_operator_by",
        "scan_machine",
        "scan_date",
        "scan_site_notes",
        "scanned_image_count",
        "image_auditor_1_by",
        "audit_date_1",
        "image_auditor_2_by",
        "audit_date_2",
        "images_sent_by",
        "images_sent_date",
      ],
    };
  },
};
</script>
<style>
#scanform_step1 {
  display: grid;
  grid-template-columns: 1fr 1fr;
}
</style>
