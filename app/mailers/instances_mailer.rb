class InstancesMailer < ActionMailer::Base
  default from: "admin@temporary.fi"
  
  def pledge_was_scheduled(proposal, user)
    @proposal = proposal
    @user = user
    unless @user.email =~ /^change@me/ ||  @user.opt_in != true
      mail(to: @user.email,  subject: "A proposal you pledged to has been scheduled: #{@proposal.name}") 
    end
  end


end
