class PostcategoriesController < ApplicationController
  
  def show
    @category = Postcategory.friendly.find(params[:id])
    @posts = @category.posts.published.order(published_at: :desc)

  
      if @site
        render template: 'posts/index', layout: @site.layout
      else
        render template: 'posts/index'
      end
  

  end
  
end