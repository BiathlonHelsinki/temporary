class HomeController < ApplicationController
  
  def index
    @news = Post.published.order(published_at: :desc)
  end
  
end