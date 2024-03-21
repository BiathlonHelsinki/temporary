class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    c = Comment.new(comment_params)
    @master = Proposal.find(params[:proposal_id]) if params[:proposal_id]

    if params[:event_id]
      @master = Event.friendly.find(params[:event_id])
      comment_params[:frontpage] = '' if comment_params[:frontpage] == "1" && (current_user != @master.primary_sponsor && current_user != @master.secondary_sponsor)
    end
    @master.comments << c
    unless @master.notifications.empty?
      @master.notifications.each do |n|
        next unless n.comments == true
        NotificationMailer.new_comment(@master, c, n.user).deliver_later
      end
    end
    if @master.save!
      flash[:notice] = t(:your_comment_was_added)
    else
      flash[:error] = t(:your_comment_was_not_added)
    end
    redirect_to(@master)
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
    redirect_to(parent)
  end

  protected

  def comment_params
    params.require(:comment).permit(:proposal_id, :item_type, :item_id, :user_id, :content, :frontpage, :attachment, :image)
  end
end
