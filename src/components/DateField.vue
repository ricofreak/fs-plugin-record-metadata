<template>
  <span class="fsrm-date-field">
    <input :id="id" type="date" :value="modelValue" @input="$emit('update:modelValue', $event.target.value)" />
    <a href="#" class="fa fa-fw fa-calendar-day" :aria-label="'Set ' + (label || 'date') + ' to today'" :title="'Set ' + (label || 'date') + ' to today'" @click.prevent="setToday"></a>
    <a v-if="modelValue" href="#" class="fa fa-fw fa-times" :aria-label="'Clear ' + (label || 'date')" :title="'Clear ' + (label || 'date')" @click.prevent="$emit('update:modelValue', '')"></a>
  </span>
</template>

<script>
export function today() {
  const d = new Date();
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 10);
}

export default {
  name: "DateField",
  props: {
    modelValue: { type: String, default: "" },
    id: { type: String, default: null },
    label: { type: String, default: "" },
  },
  emits: ["update:modelValue"],
  methods: {
    setToday() {
      this.$emit("update:modelValue", today());
    },
  },
};
</script>
