import { main } from "./App.bs";
import frogSvg from "../static/frogs.svg";
import "../static/style.css";

(() => {
  const div = document.createElement("div");
  div.style = "height: 0";
  div.innerHTML = frogSvg;
  div.querySelector("svg").setAttribute("class", "js-svg-defs");
  document.body.appendChild(div);
})();

main(document.getElementById("app"));

if ("serviceWorker" in navigator) {
  navigator.serviceWorker
    .register("sw.js")
    .then(({ scope }) => {
      console.log("Registration successful, scope is:", scope);
    })
    .catch(error => {
      console.error("Service worker registration failed, error:", error);
    });
}
