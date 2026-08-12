import { createApp } from "vue";

import NavBar from "./components/NavBar.vue";
import App from "./components/Main.vue";
import DateField from "./components/DateField.vue";


const app = createApp(App);

app.component("NavBar", NavBar);
app.component("DateField", DateField);

app.mount("#__app");
