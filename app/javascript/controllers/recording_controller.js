import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "startButton",
    "stopButton",
    "videoPreview",
    "videoPreviewText",
    "videoPreviewImg",
    "videoUploaded",
    "recordedVideoFile",
    "customUploadButton",
    "fileUploadInput"
  ];

  connect() {
    this.mediaRecorder = null;
    this.recordedChunks = [];
  }

  customUpload() {
    this.fileUploadInputTarget.click();
  }

  handleFileChange(event) {
    const fileName = event.target.files[0]?.name;
    if (fileName) {
      this.customUploadButtonTarget.querySelector(".plus-sign").textContent = "✔";
    }
  }

  async startRecording() {
    this.recordedChunks = [];
    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });

    this.videoPreviewTarget.srcObject = stream;
    this.videoPreviewTarget.muted = true;
    this.videoPreviewTextTarget.style.display = "none";
    this.videoPreviewImgTarget.style.display = "none";
    if (this.hasVideoUploadedTarget) {
      this.videoUploadedTarget.style.display = "none";
    }
    this.videoPreviewTarget.style.display = "block";
    this.videoPreviewTarget.play();

    this.mediaRecorder = new MediaRecorder(stream);
    this.mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        this.recordedChunks.push(event.data);
      }
    };
    this.mediaRecorder.onstop = () => this.handleRecordingStop(stream);

    this.mediaRecorder.start();
    this.startButtonTarget.style.display = "none";
    this.stopButtonTarget.style.display = "block";
  }

  stopRecording() {
    if (this.mediaRecorder) {
      this.mediaRecorder.stop();
      this.stopButtonTarget.style.display = "none";
      this.startButtonTarget.style.display = "block";
    }
  }

  handleRecordingStop(stream) {
    const recordedBlob = new Blob(this.recordedChunks, { type: "video/webm" });

    // Use FileReader to re-encode the Blob with proper metadata
    const fileReader = new FileReader();
    fileReader.onload = () => {
      const arrayBuffer = fileReader.result;
      const file = new File([arrayBuffer], "recorded_video.webm", { type: "video/webm" });
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(file);
      this.recordedVideoFileTarget.files = dataTransfer.files;

      this.videoPreviewTarget.srcObject = null;
      stream.getTracks().forEach((track) => track.stop());
    };

    fileReader.readAsArrayBuffer(recordedBlob);
  }
}