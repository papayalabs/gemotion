class ContactsController < ApplicationController
  def new
    @contact_form = ContactForm.new
  end

  def create
    @contact_form = ContactForm.new(contact_form_params)

    if @contact_form.valid?
      # Traitez la soumission du formulaire, par exemple, envoyez un email
      flash[:notice] = "Votre message a été envoyé avec succès."
      redirect_to contact_path
    else
      flash[:alert] = "Il y a des erreurs dans votre formulaire."
      render :new
    end
  end

  private

  def contact_form_params
    params.require(:contact_form).permit(:name, :email, :message)
  end
end
