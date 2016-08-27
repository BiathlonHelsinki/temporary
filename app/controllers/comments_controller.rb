class CommentsController < ApplicationController
  
  def create
    if params[:proposal_id]
      @master = Proposal.find(params[:proposal_id])
    end
    if params[:opencallsubmission_id]
      @master = Opencallsubmission.find(params[:opencallsubmission_id])
    end
    c = Comment.new(comment_params)
    @master.comments << c
    
    if @master.save!
      flash[:notice] = t(:your_comment_was_added)
    else
      flash[:error] = t(:your_comment_was_not_added)
    end
    redirect_to  @master
  end
  
  protected
  
  def comment_params
    params.require(:comment).permit(:proposal_id, :item_type, :item_id, :user_id, :content, :attachment, :image)
  end
  
end