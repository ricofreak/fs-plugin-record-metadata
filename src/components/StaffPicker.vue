<template>
  <span class="fsrm-staff-picker">
    <input :id="id" type="text" :value="displayValue" readonly disabled />
    <a href="#" class="fa fa-fw fa-search" :aria-label="'Find ' + (label || 'user')" title="Find staff" @click.prevent="showModal = true"></a>
    <a href="#" class="fa fa-fw fa-hand" :aria-label="'Set ' + (label || 'user') + ' to me'" title="Set to me" @click.prevent="setMe"></a>
    <a v-if="modelValue" href="#" class="fa fa-fw fa-times" :aria-label="'Clear ' + (label || 'user')" title="Clear" @click.prevent="clear"></a>

    <StaffSearchModal v-if="showModal" :title="'Find ' + (label || 'staff member')" @choose="choose" @cancel="showModal = false" />
  </span>
</template>

<script>
import StaffSearchModal from "./StaffSearchModal.vue";

export default {
  name: "StaffPicker",
  components: { StaffSearchModal },
  props: {
    modelValue: { type: [Number, String], default: null },
    displayName: { type: String, default: "" },
    id: { type: String, default: null },
    label: { type: String, default: "" },
  },
  emits: ["update:modelValue", "update:displayName"],
  data() {
    return { showModal: false };
  },
  computed: {
    displayValue() {
      return this.displayName || this.modelValue || "";
    },
  },
  methods: {
    choose(s) {
      this.$emit("update:modelValue", s.borrowernumber);
      this.$emit("update:displayName", `${s.surname}, ${s.firstname}`);
      this.showModal = false;
    },
    setMe() {
      const u = window.fsrmUser || {};
      if (!u.borrowernumber) return;
      this.$emit("update:modelValue", u.borrowernumber);
      this.$emit("update:displayName", u.name);
    },
    clear() {
      this.$emit("update:modelValue", null);
      this.$emit("update:displayName", "");
    },
  },
};
</script>

<style>
.fsrm-staff-picker { display: inline-block; }
</style>
