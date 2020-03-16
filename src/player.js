function Player(args) {
  args = args || {};

  // Delay in seconds
  this.delay = args.delay || 0.25;
  this.volume = args.volume || 0.125;

  this.audioContext = null;
  this.gainNode = null;
  this.oscillator = null;
}

const frequencies = {
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

const allNotes = Object.keys(frequencies);
const randomNote = () => {
  const note = allNotes[Math.floor(Math.random() * allNotes.length)];
  return { note, frequency: frequencies[note] };
};

Player.prototype.setDelay = function(value) {
  this.delay = value;
}

Player.prototype.setVolume = function(value) {
  this.volume = value;
}

Player.prototype.stop = function(time) {
  if (!this.audioContext) {
    return;
  }

  // Fade out the audio to prevent abruptly cutting off the sine wave which
  // results in a "popping" sound
  const fadeoutDuration = this.delay * 0.4;
  const fadeoutStartTime = time ? (time - fadeoutDuration) : this.audioContext.currentTime;
  const fadeoutStopTime = fadeoutStartTime + fadeoutDuration;

  if (this.gainNode) {
    const gain = this.gainNode.gain;
    gain.setValueAtTime(gain.value, fadeoutStartTime);
    gain.exponentialRampToValueAtTime(0.0001, fadeoutStopTime);
  }

  if (this.oscillator) { this.oscillator.stop(fadeoutStopTime); }
}

Player.prototype.play = function(notes, onNote, onStop) {
  if (notes.length === 0) {
    return;
  }

  if (this.audioContext === null) {
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }

  if (this.oscillator) {
    this.oscillator.stop();
    this.oscillator.disconnect(this.audioContext);
  }

  if (this.gainNode) {
    this.gainNode.disconnect(this.audioContext);
  }

  const gainNode = this.audioContext.createGain();
  gainNode.connect(this.audioContext.destination);
  gainNode.gain.value = this.volume;
  this.gainNode = gainNode;

  const osc = this.audioContext.createOscillator();
  osc.type = 'sine';
  osc.connect(gainNode);
  this.oscillator = osc;

  // TODO: Currently the last note is longer than it should be
  const startTime = this.audioContext.currentTime;

  let notesArray = notes.split("");
  if (notesArray[0] == ("-")) {
    // Starting with a hold note makes no sense. Treat it as a rest.
    notesArray[0] = "z";
  }

  const { callbacks } = notesArray.reduce((acc, currentNote) => {
    let note = currentNote;
    let frequency = 0;
    switch (currentNote) {
      case "z":
        frequency = 0;
        break;
      case "-":
        frequency = null;
        break;
      case "q": // Question mark
        const result = randomNote();
        note = result.note;
        frequency = result.frequency;
        break;
      default:
        frequency = frequencies[currentNote] || 0;
        break;
    }

    const noteDelaySeconds = acc.noteNumber * this.delay;
    if (frequency !== null) {
      // If not a hold note, stop the previous note early
      if (acc.noteNumber > 0) {
        osc.frequency.setValueAtTime(0, startTime + noteDelaySeconds - this.delay * 0.4);
      }

      osc.frequency.setValueAtTime(frequency, startTime + noteDelaySeconds);
    }

    const cancelable = window.setTimeout(() => {
      onNote && onNote({ index: acc.noteNumber, note });
    }, noteDelaySeconds * 1000);

    return {
      prevFrequency: frequency,
      noteNumber: acc.noteNumber + 1,
      callbacks: [...acc.callbacks, cancelable],
    };
  }, { prevFrequency: 0, noteNumber: 0, callbacks: [] });

  osc.onended = () => {
    callbacks.forEach(window.clearTimeout);
    onStop && onStop();
  };
  osc.start();

  const stopTime = startTime + notesArray.length * this.delay;
  this.stop(stopTime);
}

export default Player;

