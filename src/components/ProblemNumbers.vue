<template>
  <span>
    <span v-if="!problems.length">None</span>
    <span v-else><span v-for="(p, idx) in problems" :key="p.id"><a href="#" :class="p.open ? 'fsrm-problem-open' : 'fsrm-problem-closed'" @click.prevent="$emit('edit', p.id)">{{ p.id }}</a><span v-if="idx < problems.length - 1">, </span></span></span>
  </span>
</template>

<script>
export default {
  name: 'ProblemNumbers',
  props: {
    value: { type: String, default: '' },
  },
  emits: ['edit'],
  computed: {
    problems() {
      if (!this.value) return [];
      return this.value.split(',').map((chunk) => {
        const [id, open] = chunk.split(':');
        return { id, open: open === '1' };
      });
    },
  },
};
</script>

<style>
.fsrm-problem-open { color: #c00; font-weight: bold; }
.fsrm-problem-closed { color: #418940; }
</style>
