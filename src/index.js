import { readFileSync } from 'fs';
import Player from './player';

(() => {
  const div = document.createElement('div');

  if (process.env.NODE_ENV === 'production') {
    div.innerHTML = readFileSync(__dirname + '/../build/frogs.svg', 'utf-8');
  } else {
    div.innerHTML = readFileSync(__dirname + '/../static/frogs.svg', 'utf-8');
  }

  div.querySelector('svg').setAttribute('class', 'js-svg-defs');
  document.body.appendChild(div);
})();

const app = require('./App.ml').main(document.querySelector('#app'));

