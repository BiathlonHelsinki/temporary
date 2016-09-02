class Admin::PostsController < Admin::BaseController
  
  
  def create
    @post = Post.new(post_params)
    if @post.save
      flash[:notice] = 'Post saved.'
      redirect_to admin_posts_path
    else
      flash[:error] = "Error saving post!"
      render template: 'admin/posts/new'
    end
  end
  
  def destroy
    post = Post.friendly.find(params[:id])
    post.destroy!
    redirect_to admin_posts_path
  end
  
  def edit
    @post = Post.friendly.find(params[:id])
  end
  
  def index
    @posts = Post.all.order(created_at: :desc)
  end
  
  def new
    @post = Post.new
  end
  
  def update
    @post = Post.friendly.find(params[:id])
    if @post.update_attributes(post_params)
      flash[:notice] = 'Post details updated.'
      redirect_to admin_posts_path
    else
      flash[:error] = 'Error updating post'
    end
  end
  protected
  
  def post_params
    params.require(:post).permit(:published, :slug, :user_id, 
     :published_at, :image, :remove_image, 
      translations_attributes: [:id, :locale, :title, :body, ]
      )
  end
    
end
  