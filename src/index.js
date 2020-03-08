import { readFileSync } from 'fs';

const initFrogsSvg = () => {
  // TODO: Minify SVG first
  const frogsSvg = readFileSync(__dirname + '/../static/frogs.svg', 'utf-8');
  const div = document.createElement('div');
  div.innerHTML = frogsSvg;
  document.body.appendChild(div);
};

initFrogsSvg();

