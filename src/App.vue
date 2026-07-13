<template>
  <div class="fs-record-metadata">
    <h2>FS Record Metadata</h2>
    <p>Vue app is running. Count: {{ count }}</p>
    <button @click="count++">Increment</button>
  </div>
</template>

<script>
export default {
  name: 'App',
  data() {
    return { count: 0 }
  }
}
</script>

<style>
.fs-record-metadata {
  padding: 1rem;
}
</style>
