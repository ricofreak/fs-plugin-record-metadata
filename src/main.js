import { createApp } from "vue"

import NavBar from "./components/NavBar.vue"
import App from "./components/Main.vue"

const app = createApp(App)

app.component('NavBar', NavBar)

app.mount("#__app")
