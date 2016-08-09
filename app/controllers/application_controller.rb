class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include CanCan::ControllerAdditions
  
  rescue_from CanCan::AccessDenied do |exception|
    render json: {message: 'access denied!'}, status: 401
  end
  
  before_action :check_for_email
  private
  
  def check_for_email
    if user_signed_in?
      if current_user.email =~ /change@me/
        flash[:warning] = " Please enter a valid email address in your <a href='/users/#{current_user.id}/edit'>profile</a>."
      end
    end
  end
  
end
