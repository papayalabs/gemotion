import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="text-overlay"
export default class extends Controller {
  static targets = ["modal", "text", "position", "animation", "fontType", "fontStyle", "color", "fontSize", "previewText"];
  
  connect() {
    // Set up event listeners for UI controls
    this.setupEventListeners();
  }
  
  setupEventListeners() {
    // Listen for changes to text input
    if (this.hasTextTarget) {
      this.textTarget.addEventListener("input", () => this.updatePreview());
    }
    
    // Listen for changes to font properties
    if (this.hasFontTypeTarget) {
      this.fontTypeTarget.addEventListener("change", () => this.updatePreview());
    }
    
    if (this.hasFontStyleTarget) {
      this.fontStyleTarget.addEventListener("change", () => this.updatePreview());
    }
    
    if (this.hasFontSizeTarget) {
      this.fontSizeTarget.addEventListener("change", () => this.updatePreview());
    }
    
    if (this.hasColorTarget) {
      this.colorTarget.addEventListener("input", () => this.updatePreview());
    }
  }
  
  open(event) {
    const previewId = event.currentTarget.dataset.previewId;
    const position = event.currentTarget.dataset.position;
    
    // Store the preview ID and position for later use when saving
    document.getElementById("current-preview-id").value = previewId;
    document.getElementById("current-preview-position").value = position;
    
    // Show the modal
    const modal = document.getElementById("text-overlay-modal");
    modal.classList.remove("hidden");
    
    // Initialize preview
    this.updatePreview();
  }
  
  closeModal() {
    const modal = document.getElementById("text-overlay-modal");
    modal.classList.add("hidden");
  }
  
  updatePreview() {
    if (!this.hasPreviewTextTarget) return;
    
    // Get current values
    const text = this.hasTextTarget ? this.textTarget.value : "Sample Text";
    const fontType = this.hasFontTypeTarget ? this.fontTypeTarget.value : "Poppins";
    const fontStyle = this.hasFontStyleTarget ? this.fontStyleTarget.value : "Normal";
    const fontSize = this.hasFontSizeTarget ? this.fontSizeTarget.value : "24";
    const color = this.hasColorTarget ? this.colorTarget.value : "#ffffff";
    
    // Update the preview text
    this.previewTextTarget.textContent = text || "Sample Text";
    
    // Update styles
    this.previewTextTarget.style.fontFamily = fontType;
    this.previewTextTarget.style.color = color;
    
    // Handle font size - convert to pixels for preview display
    this.previewTextTarget.style.fontSize = `${fontSize / 3}px`; // Scale down for preview
    
    // Handle font style
    this.previewTextTarget.style.fontWeight = fontStyle.includes("Bold") ? "bold" : "normal";
    this.previewTextTarget.style.fontStyle = fontStyle.includes("Italic") ? "italic" : "normal";
  }
  
  saveOverlay() {
    const previewId = document.getElementById("current-preview-id").value;
    const position = document.getElementById("current-preview-position").value;
    
    // Get values from form
    const text = this.hasTextTarget ? this.textTarget.value : "";
    const textPosition = this.hasPositionTarget ? this.positionTarget.value : "middle";
    const animation = this.hasAnimationTarget ? this.animationTarget.value : "none";
    const fontType = this.hasFontTypeTarget ? this.fontTypeTarget.value : "Poppins";
    const fontStyle = this.hasFontStyleTarget ? this.fontStyleTarget.value : "Normal";
    const fontSize = this.hasFontSizeTarget ? this.fontSizeTarget.value : "80";
    const textColor = this.hasColorTarget ? this.colorTarget.value : "#ffffff";
    
    if (previewId) {
      // Update existing preview's hidden fields
      document.getElementById(`preview_text_${previewId}`).value = text;
      document.getElementById(`preview_text_position_${previewId}`).value = textPosition;
      document.getElementById(`preview_font_type_${previewId}`).value = fontType;
      document.getElementById(`preview_font_style_${previewId}`).value = fontStyle;
      document.getElementById(`preview_font_size_${previewId}`).value = fontSize;
      document.getElementById(`preview_animation_${previewId}`).value = animation;
      document.getElementById(`preview_text_color_${previewId}`).value = textColor;
    } else if (position) {
      // For new uploads, create new hidden fields
      const form = document.getElementById('previews-form');
      
      const createHiddenField = (name, value) => {
        const field = document.createElement('input');
        field.type = 'hidden';
        field.name = `new_preview_overlay[${position}][${name}]`;
        field.value = value;
        return field;
      };
      
      form.appendChild(createHiddenField('text', text));
      form.appendChild(createHiddenField('text_position', textPosition));
      form.appendChild(createHiddenField('start_time', 0));
      form.appendChild(createHiddenField('duration', 3));
      form.appendChild(createHiddenField('font_type', fontType));
      form.appendChild(createHiddenField('font_style', fontStyle));
      form.appendChild(createHiddenField('font_size', fontSize));
      form.appendChild(createHiddenField('animation', animation));
      form.appendChild(createHiddenField('text_color', textColor));
    }
    
    // Close the modal
    this.closeModal();
  }
}