class PostsController < ApplicationController
  
  def show
    @post = Post.friendly.find(params[:id])
    set_meta_tags title: 'News: ' + @post.title
  end
  
end