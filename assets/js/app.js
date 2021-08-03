import "../css/app.scss";

import "phoenix_html";
import { Socket } from "phoenix";
import topbar from "topbar";
import { LiveSocket } from "phoenix_live_view";
import { Hooks } from "./hooks";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, timezone },
  hooks: Hooks,
});

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
