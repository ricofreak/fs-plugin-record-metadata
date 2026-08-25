<template>
  <select v-if="options.length" :id="id" :value="modelValue || ''" @change="$emit('update:modelValue', $event.target.value || null)">
    <option value="">-- none --</option>
    <option v-for="av in options" :key="av.value" :value="av.value">{{ av.label }}</option>
  </select>
  <input v-else :id="id" type="text" :value="modelValue || ''" @input="$emit('update:modelValue', $event.target.value || null)" />
</template>

<script>
export default {
  name: "AvSelect",
  props: {
    modelValue: { type: String, default: "" },
    field: { type: String, required: true },
    id: { type: String, default: null },
  },
  emits: ["update:modelValue"],
  computed: {
    options() {
      return (window.fsrmAuthorisedValues || {})[this.field] || [];
    },
  },
};
</script>
