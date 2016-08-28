class ProposalMailer < ActionMailer::Base
  default from: "no-reply@temporary.fi"
  
  def proposal_for_review(proposal)
    @proposal = proposal
    @next_meeting = Instance.next_meeting
    mail(to: @proposal.user.email,  subject: "Proposal: #{@proposal.name} has enough pledges!") 
    @proposal.pledges.map{|x| x.user.email }.each do |recipient|
      next if recipient =~ /^change@me/
      mail(to: recipient,  subject: "Proposal: #{@proposal.name} has enough pledges!") 
    end
    
  end


end
