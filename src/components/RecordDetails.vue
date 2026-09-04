<template>
  <fieldset class="rows results" v-if="record">
    <div>
      <h3>Bibliographic info.</h3>
      <ol>
        <li><span class="label">Title:</span> {{ record.title }}</li>
        <li><span class="label">Author:</span> {{ record.author }}</li>
        <li>
          <span class="label">Publisher Date:</span>
          {{ record.publication_date }}
        </li>
        <li>
          <span class="label">Language:</span>
          {{ record.lang }}
        </li>
      </ol>
      <table
        class="table table-success table-responsive"
        v-if="record.online_links && record.online_links.length"
      >
        <thead>
          <tr>
            <th>Online link</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(link, idx) in record.online_links" :key="idx">
            <td>
              <a :href="link.url" target="_blank" rel="noopener">{{
                link.url
              }}</a>
            </td>
          </tr>
        </tbody>
      </table>
      <table class="table table-success table-responsive">
        <thead>
          <tr>
            <th>Privacy (998$f)</th>
            <th>Contract (542$r)</th>
            <th>Ex 108 (506$a)</th>
            <th>Copyright (542$l)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{{ record.privacy_998f }}</td>
            <td>{{ record.contract_542r }}</td>
            <td>{{ record.ex_108 }}</td>
            <td>{{ record.copyright_542l }}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div>
      <h3>Item info.</h3>
      <table
        class="fsrm-items table table-success table-responsive"
        v-if="record.items && record.items.length"
      >
        <thead>
          <tr>
            <th>Item type</th>
            <th>Home library</th>
            <th>Call number</th>
            <th>Barcode</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="i in record.items" :key="i.itemnumber">
            <td>{{ i.itemtype }}</td>
            <td>{{ i.branchname || i.homebranch }}</td>
            <td>{{ i.callnumber }}</td>
            <td>{{ i.barcode }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else><em>No items attached to this record.</em></p>
    </div>
  </fieldset>
</template>

<script>
export default {
  name: "RecordDetails",
  props: {
    record: { type: Object, default: null },
  },
};
</script>
