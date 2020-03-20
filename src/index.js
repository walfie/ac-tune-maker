import { readFileSync } from "fs";
import { main } from "./App.ml";

(() => {
  const div = document.createElement("div");
  div.style = "height: 0";

  if (process.env.NODE_ENV === "production") {
    div.innerHTML = readFileSync(`${__dirname}/../build/frogs.svg`, "utf-8");
  } else {
    div.innerHTML = readFileSync(`${__dirname}/../static/frogs.svg`, "utf-8");
  }

  div.querySelector("svg").setAttribute("class", "js-svg-defs");
  document.body.appendChild(div);
})();

main(document.getElementById("app"));

if ("serviceWorker" in navigator) {
  const sw = "sw.js";
  navigator.serviceWorker
    .register(sw)
    .then(({ scope }) => {
      console.log("Registration successful, scope is:", scope);
    })
    .catch(error => {
      console.error("Service worker registration failed, error:", error);
    });
}
