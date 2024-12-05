import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "cardElement", "stripeToken"];
  static values = { stripePublishableKey: String };

  async connect() {
    // Dynamically load Stripe if not already loaded
    if (typeof Stripe === "undefined") {
      await this.loadStripe();
    }

    // Initialize Stripe
    this.stripe = Stripe(this.stripePublishableKeyValue);
    this.elements = this.stripe.elements();
    this.card = this.elements.create("card");
    this.card.mount(this.cardElementTarget);
  }

  async loadStripe() {
    return new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = "https://js.stripe.com/v3/";
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  async submit(event) {
    event.preventDefault();

    // Create Stripe token
    const { token, error } = await this.stripe.createToken(this.card);
    if (error) {
      console.error("Stripe Error:", error.message);
      return;
    }

    // Pass token to the form and submit
    this.stripeTokenTarget.value = token.id;
    this.formTarget.submit();
  }
}