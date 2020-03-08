import { readFileSync } from 'fs';
import Player from './player';

const initFrogsSvg = () => {
  // TODO: Minify SVG first
  const frogsSvg = readFileSync(__dirname + '/../static/frogs.svg', 'utf-8');
  const div = document.createElement('div');
  div.innerHTML = frogsSvg;
  document.body.appendChild(div);
};

initFrogsSvg();

const player = new Player();

document.querySelector("#start").onclick = event => {
  const notes = document.querySelector("#input").value;

  const onNote = ({ index, note }) => {
    console.log(`Playing note #${index}: ${note}`);
  };
  const onStop = () => {
    console.log("Stopped playing");
  };

  player.play(notes, onNote, onStop);
};

document.querySelector("#stop").onclick = event => {
  player.stop();
}

