class CommentsController < ApplicationController
  
  
  before_filter :authenticate_user!
  
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
  
  def destroy
    @comment = Comment.find(params[:id])
    parent = @comment.item
    if can? :destroy, @comment
      @comment.destroy
      flash[:notice] = 'Your comment has been deleted.'
    else
      flash[:error] = ' You do not have permission to delete this comment.'
    end
    redirect_to parent
  end
  
  protected
  
  def comment_params
    params.require(:comment).permit(:proposal_id, :item_type, :item_id, :user_id, :content, :attachment, :image)
  end
  
end