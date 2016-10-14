class PostsController < ApplicationController
  
  def index
    @posts = Post.published.order(published_at: :desc)
    set_meta_tags title: 'News'
  end
  
  def show
    @post = Post.friendly.find(params[:id])
    set_meta_tags title: 'News: ' + @post.title
  end
  
end