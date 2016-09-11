class TransfersMailer < ActionMailer::Base
  default from: "admin@temporary.fi"
  
  def received_temps(sender, recipient, amount, reason = nil)
    @sender = sender
    @recipient = recipient
    @amount = amount
    @reason = reason
    unless recipient.email =~ /change@me/
      mail(to: recipient.email,  subject: "You've got Temps! (from #{@sender.display_name})")
    end    
  end


end
