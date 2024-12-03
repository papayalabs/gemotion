import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["waveformCanvas", "playPauseButton"];

  connect() {
    const audioSrc = this.element.dataset.audioSrc;
    console.log(audioSrc);
    const waveformData = JSON.parse(this.element.dataset.waveform).data;

    // Process waveform: Trim zeros and downsample to 32 bars (half of 64)
    const processedWaveform = this.processWaveform(waveformData, 48); // Target 32 bars

    const canvas = this.waveformCanvasTarget;
    const playPauseButton = this.playPauseButtonTarget;
    const ctx = canvas.getContext("2d");
    const audio = new Audio(audioSrc);

    // Canvas dimensions
    canvas.width = 512; // Full width
    canvas.height = 60; // Height for visual appearance

    // Create gradient for waveform
    const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);
    gradient.addColorStop(0.1949, "#C9E1FF"); // 19.49% from top
    gradient.addColorStop(0.6063, "#0D6783"); // 60.63% from top
    gradient.addColorStop(0.9092, "#163F50"); // 90.92% from top

    // Render the static waveform
    const drawStaticWaveform = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      const barWidth = (canvas.width / processedWaveform.length) - 4; // Space between bars
      const maxBarHeight = canvas.height * 0.7; // Max bar height (70% of canvas height)
      let x = 0;

      for (let value of processedWaveform) {
        const barHeight = (Math.abs(value) / 255) * maxBarHeight * 2.7; // Scale down
        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.roundRect(x, canvas.height - barHeight, barWidth, barHeight, 2); // Rounded bars
        ctx.fill();
        x += barWidth + 4; // Increase gap between bars
      }
    };

    // Play/Pause functionality
    const togglePlayPause = () => {
      const iconElement = playPauseButton.querySelector(".play-button-icon, .stop-button-icon");

      if (audio.paused) {
        audio.play();
        playPauseButton.classList.add("playing");
        if (iconElement) {
          iconElement.classList.remove("play-button-icon");
          iconElement.classList.add("stop-button-icon");
        }
      } else {
        audio.pause();
        playPauseButton.classList.remove("playing");
        if (iconElement) {
          iconElement.classList.remove("stop-button-icon");
          iconElement.classList.add("play-button-icon");
        }
      }
    };

    // Draw the static waveform
    drawStaticWaveform();

    // Attach event listener to the play/pause button
    playPauseButton.addEventListener("click", togglePlayPause);
  }

  /**
   * Process the waveform by trimming zeros and downsampling
   * @param {Array} waveformData - Original waveform data
   * @param {number} targetBars - Target number of bars
   * @returns {Array} - Processed waveform data
   */
  processWaveform(waveformData, targetBars) {
    // Trim leading and trailing zeros
    const trimmedWaveform = this.trimZeros(waveformData);

    // Downsample to match the target number of bars
    const downsampledWaveform = this.downsample(trimmedWaveform, targetBars);

    return downsampledWaveform;
  }

  /**
   * Trim leading and trailing zeros from waveform data
   * @param {Array} data - Original waveform data
   * @returns {Array} - Trimmed waveform data
   */
  trimZeros(data) {
    let start = 0;
    let end = data.length - 1;

    // Find first non-zero value
    while (start < data.length && data[start] === 0) {
      start++;
    }

    // Find last non-zero value
    while (end >= 0 && data[end] === 0) {
      end--;
    }

    return data.slice(start, end + 1);
  }

  /**
   * Downsample waveform data to target number of bars
   * @param {Array} data - Trimmed waveform data
   * @param {number} targetBars - Target number of bars
   * @returns {Array} - Downsampled waveform data
   */
  downsample(data, targetBars) {
    const downsampled = [];
    const chunkSize = Math.ceil(data.length / targetBars);

    for (let i = 0; i < data.length; i += chunkSize) {
      const chunk = data.slice(i, i + chunkSize);
      downsampled.push(Math.max(...chunk)); // Use the max value in the chunk
    }

    return downsampled;
  }
}

// Utility to create rounded rectangles
CanvasRenderingContext2D.prototype.roundRect = function (x, y, width, height, radius) {
  this.beginPath();
  this.moveTo(x + radius, y);
  this.lineTo(x + width - radius, y);
  this.quadraticCurveTo(x + width, y, x + width, y + radius);
  this.lineTo(x + width, y + height - radius);
  this.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  this.lineTo(x + radius, y + height);
  this.quadraticCurveTo(x, y + height, x, y + height - radius);
  this.lineTo(x, y + radius);
  this.quadraticCurveTo(x, y, x + radius, y);
  this.closePath();
};