import { readFileSync } from 'fs';
import Player from './player';

const initFrogsSvg = () => {
  // TODO: Minify SVG first
  const frogsSvg = readFileSync(__dirname + '/../static/frogs.svg', 'utf-8');
  const div = document.createElement('div');
  div.innerHTML = frogsSvg;
  div.querySelector('svg').setAttribute('class', 'js-svg-defs');
  document.body.appendChild(div);
};

initFrogsSvg();

const app = require('./App.ml').main(document.querySelector('#app'));

