<template>
  <div class="fsrm-access-level" :class="'fsrm-access-' + slug">
    <div class="fsrm-access-label">Access level</div>
    <div class="fsrm-access-value"><strong>{{ value || 'Undetermined' }}</strong></div>
    <div v-if="source" class="fsrm-access-source">{{ sourceLabel }}</div>
  </div>
</template>

<script>
const SOURCE_LABELS = {
  "998f": "from 998$f",
  "542r": "from 542$r",
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
      padding: .6rem 1rem;
      margin: 0 0 1rem 0;
      background: #FFFFC5;
      color: #666;
    }
</style>
