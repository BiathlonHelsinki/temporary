class PostsController < ApplicationController
  
  def index
    @posts = Post.published.order(published_at: :desc)
    @posts += Comment.frontpage
    @posts.sort_by!(&:feed_date)
    @posts.reverse!
    set_meta_tags title: 'News'
  end
  
  def show
    @post = Post.friendly.find(params[:id])
    set_meta_tags title: 'News: ' + @post.title
  end
  
end