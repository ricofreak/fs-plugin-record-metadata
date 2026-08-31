<template>
  <li class="fsrm-access-level" :title="sourceLabel">
    <label for="access_level">Access level: </label>
    <span id="access_level" class="fsrm-access-level" :class="'fsrm-access-' + slug">
      {{ value || 'Undetermined' }}
    </span>
  </li>
</template>

<script>
const SOURCE_LABELS = {
  "998f": "from 998$f",
  "542r": "from 542$r",
  "506a": "from 506$a",
  contract: "from contract permission",
  none: "not yet determined",
};

export default {
  name: "AccessLevel",
  props: {
    value: { type: String, default: "" },
    source: { type: String, default: "" },
    id: { type: String, default: "access" },
  },
  computed: {
    sourceLabel() {
      return SOURCE_LABELS[this.source];
    },
  },
};
</script>
<style>
    .fsrm-access-level {
        background: #ffffc5;
    }
</style>
