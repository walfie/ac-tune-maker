import { main } from "./App.bs";
import frogSvg from "../static/frogs.svg";
import "../static/style.css";

const svgContainer = (() => {
  const div = document.createElement("div");
  div.style = "height: 0";
  document.body.appendChild(div);
  return div;
})();

const getLanguage = () => {
  return (
    localStorage.getItem("lang") ||
    (navigator.languages && navigator.languages[0]) ||
    navigator.language ||
    "en-US"
  );
};

const run = model => {
  svgContainer.innerHTML = frogSvg;
  svgContainer.querySelector("svg").setAttribute("class", "js-svg-defs");

  return main(document.getElementById("app"), getLanguage(), model);
};

let app = run();

if (module.hot) {
  module.hot.accept(["./App.bs", "../static/frogs.svg"], () => {
    app.shutdown().then(model => {
      app = run(model);
    });
  });
}

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
