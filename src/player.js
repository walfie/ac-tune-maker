function Player(args) {
  args = args || {};

  // Delay in seconds
  this.delay = args.delay || 0.2;
  this.volume = args.volume || 0.1;

  this.audioContext = null;
  this.gainNode = null;
  this.oscillator = null;
}

const freqs = {
  "g": 392.00,
  "a": 440.00,
  "b": 493.88,
  "c": 523.25,
  "d": 587.33,
  "e": 659.25,
  "f": 698.46,
  "G": 783.99,
  "A": 880.00,
  "B": 987.77,
  "C": 1046.50,
  "D": 1174.66,
  "E": 1318.51,
};

const allNotes = Object.values(freqs);

Player.prototype.setDelay = function(value) {
  this.delay = value;
}

Player.prototype.setVolume = function(value) {
  this.volume = value;
}

Player.prototype.stop = function() {
  if (this.oscillator) {
    this.oscillator.stop();
  }
}

Player.prototype.play = function(notes, onNote, onStop) {
  if (this.audioContext === null) {
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();

    this.gainNode = this.audioContext.createGain();
    this.gainNode.connect(this.audioContext.destination);
    this.gainNode.gain.value = this.volume;
  }

  if (this.oscillator) {
    // TODO: Callback for stop
    this.oscillator.stop();
    this.oscillator.disconnect(this.audioContext);
  }

  const osc = this.audioContext.createOscillator();
  osc.type = 'sine';
  osc.connect(this.gainNode);
  this.oscillator = osc;

  const startTime = this.audioContext.currentTime;
  const { callbacks } = notes.split('').reduce((acc, currentNote) => {
    let note = 0;
    switch (currentNote) {
      case "z":
        note = 0;
        break;
      case "-":
        note = acc.prevNote;
        break;
      case "?":
        note = allNotes[Math.floor(Math.random() * allNotes.length)];
        break;
      default:
        note = freqs[currentNote] || 0;
        break;
    }

    // TODO: Callback
    const noteDelaySeconds = acc.noteNumber * this.delay;
    osc.frequency.setValueAtTime(note, startTime + noteDelaySeconds);

    const cancelable = window.setTimeout(() => {
      onNote && onNote({ index: acc.noteNumber, note: currentNote });
    }, noteDelaySeconds * 1000);

    return {
      prevNote: note,
      noteNumber: acc.noteNumber + 1,
      callbacks: [...acc.callbacks, cancelable],
    };
  }, { prevNote: 0, noteNumber: 0, callbacks: [] });

  osc.onended = () => {
    callbacks.forEach(window.clearTimeout);
    onStop && onStop();
  };
  osc.start();
  osc.stop(startTime + notes.length * this.delay);
}

export default Player;

