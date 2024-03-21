class EmailsController < ApplicationController
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  caches_page :show

  def show
    @email = Email.friendly.find(params[:id])
    @user = current_user if user_signed_in?
    @body = ERB.new(@email.body).result(binding).html_safe
    set_meta_tags(title: @email.subject)
  end
end
