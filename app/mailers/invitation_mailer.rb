class InvitationMailer < ApplicationMailer

    def send_invitation
        @email = params[:email]
        @url = params[:url]
        mail(to: @email, subject: 'Invitation a participer à GeMotion')
    end
end
