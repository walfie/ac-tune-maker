if(!self.define){const e=e=>{"require"!==e&&(e+=".js");let r=Promise.resolve();return i[e]||(r=new Promise(async r=>{if("document"in self){const i=document.createElement("script");i.src=e,document.head.appendChild(i),i.onload=r}else importScripts(e),r()})),r.then(()=>{if(!i[e])throw new Error(`Module ${e} didn’t register its module`);return i[e]})},r=(r,i)=>{Promise.all(r.map(e)).then(e=>i(1===e.length?e[0]:e))},i={require:Promise.resolve(r)};self.define=(r,s,n)=>{i[r]||(i[r]=Promise.resolve().then(()=>{let i={};const t={uri:location.origin+r.slice(1)};return Promise.all(s.map(r=>{switch(r){case"exports":return i;case"module":return t;default:return e(r)}})).then(e=>{const r=n(...e);return i.default||(i.default=r),i})}))}}define("./sw.js",["./workbox-9ca5159e"],(function(e){"use strict";e.skipWaiting(),e.clientsClaim(),e.precacheAndRoute([{url:"index.html",revision:"bcaf92c88d1b40d446e0a81ed6e1d334"},{url:"main.584740c4.js",revision:"72b469972d96e061162c65bcdff4d433"},{url:"main.5db411fe.css",revision:"fe8f3edec7d3c2c232f0222f1f2d1993"},{url:"manifest.webmanifest",revision:"6399cc10048641dea13b70bcfed80c1f"}],{}),e.registerRoute(/\/.+\.[0-9a-f]+\.[a-z]+$/i,new e.CacheFirst,"GET")}));