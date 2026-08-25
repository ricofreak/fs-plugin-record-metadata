<template>
  <div class="fsrm-access-level" :class="'fsrm-access-' + slug">
    <span class="fsrm-access-label">Access level</span>
    <span class="fsrm-access-value">{{ value || 'Undetermined' }}</span>
    <span v-if="source" class="fsrm-access-source">{{ sourceLabel }}</span>
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
  display: inline-block;
  padding: .6rem 1rem;
  margin: 0 0 1rem 0;
  border-left: 4px solid #999;
  background: #FFFFC5;
  border-radius: 3px;
  width: 100%;
}
.fsrm-access-label {
  display: block;
  font-size: .8rem;
  text-transform: uppercase;
  letter-spacing: .05em;
  color: #666;
}
.fsrm-access-value {
  display: block;
  font-size: 1.2rem;
  font-weight: bold;
}
.fsrm-access-source {
  display: block;
  font-size: .8rem;
  color: #666;
}

/* restrictive levels stand out */
.fsrm-access-privacy-restricted,
.fsrm-access-denied {
  border-left-color: #c00;
  background: #fdf0f0;
}
.fsrm-access-undetermined {
  border-left-color: #e0a800;
  background: #fdf9ec;
}
.fsrm-access-public,
.fsrm-access-full-permission {
  border-left-color: #418940;
  background: #f1f8f1;
}
</style>
