import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static targets = [
    "customUploadButtonVideos",
    "customUploadButtonPhotos",
    "fileUploadInputVideos",
    "fileUploadInputPhotos",
    "chaptersList",
    "chapterOrder"
  ];

  connect() {
    this.uploadedVideos = [];
    this.uploadedPhotos = [];
    this.initializeSortableForAll();
  }

  triggerVideoUpload(event) {
    const chapterId = event.currentTarget.dataset.id;
    const fileInput = document.querySelector(
      `input[type="file"][data-id="${chapterId}"][accept="video/*"]`
    );

    if (fileInput) {
      fileInput.click();
    } else {
      console.error(`Video file input not found for chapter ${chapterId}`);
    }
  }

  // Trigger file input for photos
  triggerPhotoUpload(event) {
    const chapterId = event.currentTarget.dataset.id;
    const fileInput = document.querySelector(
      `input[type="file"][data-id="${chapterId}"][accept="image/*"]`
    );

    if (fileInput) {
      fileInput.click();
    } else {
      console.error(`Photo file input not found for chapter ${chapterId}`);
    }
  }

  // Handle video file selection
  handleVideoChange(event) {
    const chapterId = event.target.closest(".chapter-item").dataset.id;
    const videoGallery = document.getElementById(`edit-video-gallery-${chapterId}`);
    const videosOrderInput = document.getElementById(`videos_order_${chapterId}`);

    videoGallery.innerHTML = ""; // Clear existing video containers
    Array.from(event.target.files).forEach((file) => {
      this.addVideoContainer(videoGallery, file, event.target);
    });

    this.updateOrder(videoGallery, videosOrderInput);
    this.initializeSortableForGallery(videoGallery, videosOrderInput);
    const fileName = event.target.files[0]?.name;
    if (fileName) {
      this.customUploadButtonVideosTarget.querySelector(".plus-sign").textContent = "✔";
    }
  }

  // Handle photo file selection
  handlePhotoChange(event) {
    const chapterId = event.target.closest(".chapter-item").dataset.id;
    const photoGallery = document.getElementById(`edit-photo-gallery-${chapterId}`);
    const photosOrderInput = document.getElementById(`images_order_${chapterId}`);

    photoGallery.innerHTML = ""; // Clear existing photo containers
    Array.from(event.target.files).forEach((file) => {
      this.addPhotoContainer(photoGallery, file, event.target);
    });

    this.updateOrder(photoGallery, photosOrderInput);
    this.initializeSortableForGallery(photoGallery, photosOrderInput);
    const fileName = event.target.files[0]?.name;
    if (fileName) {
      this.customUploadButtonPhotosTarget.querySelector(".plus-sign").textContent = "✔";
    }
  }

  // Initialize sortable for all chapters
  initializeSortableForAll() {
    const chapterOrderInput = document.getElementById("chapter_order");
    if (this.hasChaptersListTarget) {
      new Sortable(this.chaptersListTarget, {
        animation: 150,
        onEnd: () => {
          const order = Array.from(this.chaptersListTarget.children).map((item) =>
            item.dataset.id
          );
          chapterOrderInput.value = order.join(",");
        },
      });

      Array.from(this.chaptersListTarget.children).forEach((chapterItem) => {
        const chapterId = chapterItem.dataset.id;
        const videoGallery = document.getElementById(`edit-video-gallery-${chapterId}`);
        const photoGallery = document.getElementById(`edit-photo-gallery-${chapterId}`);
        const videosOrderInput = document.getElementById(`videos_order_${chapterId}`);
        const photosOrderInput = document.getElementById(`images_order_${chapterId}`);

        this.initializeSortableForGallery(videoGallery, videosOrderInput);
        this.initializeSortableForGallery(photoGallery, photosOrderInput);
      });
    }
  }

  // Initialize sortable for a specific gallery
  initializeSortableForGallery(gallery, orderInput) {
    if (gallery) {
      new Sortable(gallery, {
        animation: 150,
        onEnd: () => this.updateOrder(gallery, orderInput),
      });
    }
  }

  // Delete chapter
  deleteChapter(event) {
    const deleteButton = event.target.closest(".delete-chap-icon-btn");
    if (deleteButton) {
      const url = deleteButton.dataset.url;
      const confirmation = deleteButton.dataset.confirm;

      if (confirm(confirmation)) {
        fetch(url, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
            Accept: "application/json",
            "Content-Type": "application/json",
          },
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.message) {
              window.location.reload();
            } else {
              alert("Failed to delete the chapter. Please try again.");
            }
          })
          .catch((error) => {
            console.error("Error:", error);
            alert("An error occurred. Please try again.");
          });
      }
    }
  }

  // Delete attachment
  deleteAttachment(event) {
    const purgeButton = event.target.closest(".purge-attachment-icon-btn");
    if (purgeButton) {
      const url = purgeButton.dataset.url;
      if (confirm("Are you sure you want to delete this attachment?")) {
        fetch(url, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
            Accept: "application/json",
            "Content-Type": "application/json",
          },
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.message) {
              purgeButton.closest(".edit-image-container, .edit-video-container").remove();
            } else {
              alert("Failed to delete the attachment. Please try again.");
            }
          })
          .catch((error) => {
            console.error("Error:", error);
            alert("An error occurred. Please try again.");
          });
      }
    }
  }

  // Update order of items in a gallery
  updateOrder(gallery, orderInput) {
    const order = Array.from(gallery.children).map((item) => item.dataset.fileName);
    orderInput.value = order.join(",");
  }

  // Update input file list
  updateFileInput(inputElement, fileList) {
    const dataTransfer = new DataTransfer();
    fileList.forEach((file) => dataTransfer.items.add(file));
    inputElement.files = dataTransfer.files;
  }

  // Add video container
  addVideoContainer(gallery, file, inputElement) {
    const fileName = file.name;
    this.uploadedVideos.push(file);

    const videoContainer = document.createElement("div");
    videoContainer.classList.add("edit-video-container", "new-video-container");
    videoContainer.dataset.fileName = fileName;

    const videoPreview = document.createElement("video");
    videoPreview.controls = true;
    videoPreview.src = URL.createObjectURL(file);

    const deleteButton = document.createElement("div");
    deleteButton.classList.add("purge-attachment-icon");
    deleteButton.innerHTML = `<img src="/assets/icons/delete-icon.png" alt="Delete Icon" class="purge-chap-icon">`;
    deleteButton.addEventListener("click", () => {
      this.uploadedVideos = this.uploadedVideos.filter((item) => item.name !== fileName);
      this.updateFileInput(inputElement, this.uploadedVideos);

      this.updateOrder(gallery, gallery.closest(".chapter-item").querySelector(`[id^='videos_order_']`));
      videoContainer.remove();
    });

    videoContainer.append(videoPreview, deleteButton);
    gallery.appendChild(videoContainer);
  }

  // Add photo container
  addPhotoContainer(gallery, file, inputElement) {
    const fileName = file.name;
    this.uploadedPhotos.push(file);

    const photoContainer = document.createElement("div");
    photoContainer.classList.add("edit-image-container", "new-image-container");
    photoContainer.dataset.fileName = fileName;

    const photoPreview = document.createElement("img");
    photoPreview.classList.add("prev-image");
    photoPreview.src = URL.createObjectURL(file);

    const deleteButton = document.createElement("div");
    deleteButton.classList.add("purge-attachment-icon");
    deleteButton.innerHTML = `<img src="/assets/icons/delete-icon.png" alt="Delete Icon" class="purge-chap-icon">`;
    deleteButton.addEventListener("click", () => {
      this.uploadedPhotos = this.uploadedPhotos.filter((item) => item.name !== fileName);
      this.updateFileInput(inputElement, this.uploadedPhotos);

      this.updateOrder(gallery, gallery.closest(".chapter-item").querySelector(`[id^='images_order_']`));
      photoContainer.remove();
    });

    photoContainer.append(photoPreview, deleteButton);
    gallery.appendChild(photoContainer);
  }
}