<template>
  <ScanningForm
    :entry="entry"
    :field-keys="fieldKeys"
    :prev-step="1"
    prev-step-label="Save and return to step 1"
    @saved="$emit('saved', $event)"
    @step="$emit('step', $event)"
  >
    <template #fields="{ form, names, selected, editProblem, addProblem }">
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
            <input id="callnumbers" :value="selected.callnumbers" readonly disabled />
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
            <AvSelect id="ocr_site" field="ocr_site" v-model="form.ocr_site" />
          </li>
          <li>
            <label for="ocr_date">OCR date:</label>
            <DateField id="ocr_date" v-model="form.ocr_date" />
          </li>
          <li>
            <label for="pdf_ready_for_review">PDF ready for review:</label>
            <input id="pdf_ready_for_review" v-model.trim="form.pdf_ready_for_review" />
          </li>
          <li>
            <label for="review_by">Published image review by:</label>
            <StaffPicker id="review_by" label="Published image review by" v-model="form.review_by" v-model:displayName="names.review_by" />
          </li>
          <li>
            <label for="review_start_date">Review start date:</label>
            <DateField id="review_start_date" v-model="form.review_start_date" />
          </li>
          <li>
            <label for="review_complete_date">Review complete date:</label>
            <DateField id="review_complete_date" v-model="form.review_complete_date" />
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
            <DateField id="pdf_loaded_date" v-model="form.pdf_loaded_date" />
          </li>
          <li>
            <label for="pages_online">Loaded pages #:</label>
            <textarea id="pages_online" v-model.trim="form.pages_online"></textarea>
          </li>
        </ol>

        <ol>
          <li>
            <label for="pdf_orem_archived_date">PDF Orem archive date:</label>
            <DateField id="pdf_orem_archived_date" v-model="form.pdf_orem_archived_date" />
          </li>
          <li>
            <label for="pdf_orem_drive_name">PDF Orem drive name:</label>
            <input id="pdf_orem_drive_name" v-model.trim="form.pdf_orem_drive_name" />
          </li>
          <li>
            <label for="pdf_copy2_archived_date">PDF Copy2 archive date:</label>
            <DateField id="pdf_copy2_archived_date" v-model="form.pdf_copy2_archived_date" />
          </li>
          <li>
            <label for="pdf_copy2_drive_name">PDF Copy2 drive name:</label>
            <input id="pdf_copy2_drive_name" v-model.trim="form.pdf_copy2_drive_name" />
          </li>
          <li>
            <label for="tiff_orem_archived_date">TIFF Orem archive date:</label>
            <DateField id="tiff_orem_archived_date" v-model="form.tiff_orem_archived_date" />
          </li>
          <li>
            <label for="tiff_orem_drive_name">TIFF Orem drive name:</label>
            <input id="tiff_orem_drive_name" v-model.trim="form.tiff_orem_drive_name" />
          </li>
          <li>
            <label for="tiff_copy2_archived_date">TIFF Copy2 archive date:</label>
            <DateField id="tiff_copy2_archived_date" v-model="form.tiff_copy2_archived_date" />
          </li>
          <li>
            <label for="tiff_copy2_drive_name">TIFF Copy2 drive name:</label>
            <input id="tiff_copy2_drive_name" v-model.trim="form.tiff_copy2_drive_name" />
          </li>
          <li>
            <label for="images_removed_by">Image removal request by:</label>
            <StaffPicker id="images_removed_by" label="Image removal request by" v-model="form.images_removed_by" v-model:displayName="names.images_removed_by" />
          </li>
          <li>
            <label for="images_removed_date">Image removal date:</label>
            <DateField id="images_removed_date" v-model="form.images_removed_date" />
          </li>
          <li>
            <label for="images_removed_notes">Image removal notes:</label>
            <textarea id="images_removed_notes" v-model.trim="form.images_removed_notes"></textarea>
          </li>
        </ol>
      </fieldset>
    </template>
  </ScanningForm>
</template>

<script>
import ScanningForm from "./ScanningForm.vue";
import ProblemNumbers from "./ProblemNumbers.vue";

export default {
  name: "ScanningViewTwo",
  components: { ScanningForm, ProblemNumbers },
  props: {
    entry: { type: Object, default: null },
  },
  emits: ["saved", "step"],
  data() {
    return {
      fieldKeys: [
        "secondary_identifier",
        "volume_description",
        "owning_institution",
        "access",
        "number_of_pages",

        "ocr_site",
        "ocr_date",
        "pdf_ready_for_review",
        "review_by",
        "review_start_date",
        "review_complete_date",
        "image_review_notes",
        "pdf_sent_to",
        "pdf_loaded_date",
        "pages_online",

        "pdf_orem_archived_date",
        "pdf_orem_drive_name",
        "pdf_copy2_archived_date",
        "pdf_copy2_drive_name",
        "tiff_orem_archived_date",
        "tiff_orem_drive_name",
        "tiff_copy2_archived_date",
        "tiff_copy2_drive_name",

        "images_removed_by",
        "images_removed_date",
        "images_removed_notes",
      ],
    };
  },
};
</script>

<style>
#scanform_step2 {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
}
</style>
