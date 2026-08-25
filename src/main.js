import { createApp } from "vue";

import NavBar from "./components/NavBar.vue";
import App from "./components/Main.vue";
import DateField from "./components/DateField.vue";
import StaffPicker from "./components/StaffPicker.vue";
import AvSelect from "./components/AvSelect.vue";

const app = createApp(App);

app.component("NavBar", NavBar);
app.component("DateField", DateField);
app.component("StaffPicker", StaffPicker);
app.component("AvSelect", AvSelect);

app.mount("#__app");
