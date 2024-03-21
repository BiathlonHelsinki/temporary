class ApplicationController < ActionController::Base
  self.page_cache_directory = :locale_cache_directory
  protect_from_forgery with: :exception
  include CanCan::ControllerAdditions
  before_action :check_service_status
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :are_we_open?
  before_action :get_locale

  rescue_from CanCan::AccessDenied do |_exception|
    render json: { message: 'access denied!' }, status: :unauthorized
  end

  before_action :check_for_email

  private

  def are_we_open?
    return if request.xhr?
    Opensession.uncached do
      sesh = Opensession.by_node(1).find_by(closed_at: nil)
    end
    sesh = Opensession.by_node(1).find_by(closed_at: nil)
    @temporary_is_open = if sesh.nil?
      false
    else
      true
    end
  end

  def check_for_email
    if user_signed_in?
      flash[:warning] = " Please enter a valid email address in your <a href='/users/#{current_user.id}/edit'>profile</a>." if current_user.email =~ /change@me/
    else
      save_location unless !request.fullpath.match(%r{^/users}).nil? || request.fullpath =~ /\.json/
    end
  end

  def check_service_status
    @parity_status = Net::Ping::TCP.new(ENV['parity_server'], ENV['parity_port'], 1).ping?
    @geth_status = Net::Ping::TCP.new(ENV['geth_server'], ENV['geth_port'], 1).ping?
    @api_status = Net::Ping::TCP.new(ENV['biathlon_api_server'], ENV['biathlon_api_port'], 1).ping?
    @dapp_status = Net::Ping::TCP.new(ENV['dapp_server'], ENV['dapp_port'], 1).ping?
  end

  protected

  def after_sign_in_path_for(_resource)
    return session.delete(:return_to) if session[:return_to]

    '/'
  end

  def configure_permitted_parameters
    added_attrs = %i[username email password password_confirmation remember_me]
    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  def save_location
    session[:return_to] = request.fullpath
  end

  def get_locale
    session[:locale] = params[:locale] if params[:locale]

    if session[:locale].blank?
      available = %w{en fi}
      I18n.locale = http_accept_language.compatible_language_from(available)
      session[:locale] = I18n.locale
    else
      I18n.locale = session[:locale]
    end
  end

  def locale_cache_directory
    page = params[:page]&.to_s || "1"
    Rails.public_path.join('cached_pages', I18n.locale.to_s, page)
  end
end
