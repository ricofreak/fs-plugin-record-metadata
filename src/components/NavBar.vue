<template>
  <nav class="fsrm-navbar">
    <ul>
      <li v-for="item in items" :key="item.id" :class="{ active: item.id === current }">
        <a href="#" @click.prevent="$emit('navigate', item.id)">{{ item.label }}</a>
      </li>
    </ul>
  </nav>
</template>

<script>
export default {
  name: 'NavBar',
  props: {
    current: { type: String, required: true },
  },
  emits: ['navigate'],
  data() {
    return {
      items: [
        { id: 'search',  label: 'Search' },
        { id: 'create',  label: 'New entry' },
        { id: 'reports', label: 'Reports' },
      ],
    };
  },
};
</script>

<style>
.fsrm-navbar ul { display: flex; gap: 0; list-style: none; margin: 0 0 1rem 0; padding: 0; border-bottom: 2px solid #e0e0e0; }
.fsrm-navbar li a { display: block; padding: .5rem 1rem; text-decoration: none; }
.fsrm-navbar li.active a { border-bottom: 2px solid #418940; margin-bottom: -2px; font-weight: bold; }
</style>
