import { Controller } from '@hotwired/stimulus';
import WaveSurfer from 'wavesurfer.js';

export default class extends Controller {
  static targets = ['playButton', 'waveform'];

  connect() {
    // Initialize WaveSurfer instance lazily
    this.audioSrc = this.element.dataset.audioSrc;
    this.wavesurfer = null;

    // Ensure AudioContext is initialized on user interaction
    this.initializeAudioContext();
  }

  play(event) {
    event.preventDefault();

    // Lazy initialize WaveSurfer
    if (!this.wavesurfer) {
      this.initializeWaveSurfer();
    }

    // Pause all other audio players
    this.constructor.audioPlayers.forEach((otherPlayer) => {
      if (otherPlayer !== this.wavesurfer) otherPlayer.pause();
    });

    // Toggle play/pause for this player
    if (this.wavesurfer.isPlaying()) {
      this.wavesurfer.pause();
      this.playButtonTarget.classList.remove('playing');
    } else {
      this.wavesurfer.play();
      this.playButtonTarget.classList.add('playing');
    }
  }

  initializeWaveSurfer() {
    // Create WaveSurfer instance with gradient colors
    this.wavesurfer = WaveSurfer.create({
      container: this.waveformTarget,
      waveColor: this.createVerticalGradient(),
      progressColor: this.createVerticalGradient(),
      cursorWidth: 0, // Hide cursor
      barWidth: 3, // Bar width for waveform
      barHeight: 1, // Wave bar height scale
      barGap: 2, // Gap between bars
      height: 40, // Waveform height
      responsive: true,
    });

    this.wavesurfer.load(this.audioSrc);

    // Add this instance to the global audioPlayers array
    this.constructor.audioPlayers.push(this.wavesurfer);
  }

  initializeAudioContext() {
    if (!this.constructor.audioContext) {
      this.constructor.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    }

    document.addEventListener(
      'click',
      () => {
        if (this.constructor.audioContext.state === 'suspended') {
          this.constructor.audioContext.resume();
        }
      },
      { once: true } // Ensure the event is attached only once
    );
  }

  createVerticalGradient() {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    canvas.height = 100; // Set a height for gradient definition
    const gradient = ctx.createLinearGradient(0, canvas.height, 0, 0); // Gradient from bottom to top
    gradient.addColorStop(0, '#163F50'); // Bottom color
    gradient.addColorStop(0.5, '#0D6783'); // Middle color
    gradient.addColorStop(1, '#C9E1FF'); // Top color

    return gradient;
  }

  disconnect() {
    // Cleanup to free memory
    if (this.wavesurfer) {
      this.wavesurfer.destroy();
      this.constructor.audioPlayers = this.constructor.audioPlayers.filter((player) => player !== this.wavesurfer);
    }
  }

  static audioPlayers = []; // Static property to track all players
  static audioContext = null; // Shared AudioContext across all controllers
}
