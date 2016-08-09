class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :force_english
  before_action :check_service_status
  before_action :authenticate_user!
  before_action :authenticate_admin!
  load_and_authorize_resource except: [:home], find_by: :slug
  
  def authenticate_admin!
    redirect_to root_path unless current_user.has_role? :admin
  end
  
  def check_permissions
    authorize! :create, resource
  end
  
  def check_service_status
    @geth_status = Net::Ping::TCP.new(ENV['geth_server'],  ENV['geth_port'], 1).ping?
    @api_status = Net::Ping::TCP.new(ENV['biathlon_api_server'],  ENV['biathlon_api_port'], 1).ping?
    @dapp_status = Net::Ping::TCP.new(ENV['dapp_server'], ENV['dapp_port'], 1).ping?
  end
  
  def force_english
    I18n.locale = 'en'
  end
  
  def home

  end

end
  