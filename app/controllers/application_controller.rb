class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include CanCan::ControllerAdditions
  before_action :check_service_status
  before_action :configure_permitted_parameters, if: :devise_controller?
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
  
  def check_service_status
    @geth_status = Net::Ping::TCP.new(ENV['geth_server'],  ENV['geth_port'], 1).ping?
    @api_status = Net::Ping::TCP.new(ENV['biathlon_api_server'],  ENV['biathlon_api_port'], 1).ping?
    @dapp_status = Net::Ping::TCP.new(ENV['dapp_server'], ENV['dapp_port'], 1).ping?
  end
  
  protected

  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs

  end
  
    
end
