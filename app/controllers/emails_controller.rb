class EmailsController < ApplicationController
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  

  
  def show
    @email = Email.friendly.find(params[:id])
    if user_signed_in?
      @user = current_user
    end
    @body = ERB.new(@email.body).result(binding).html_safe
    set_meta_tags title: @email.subject
  end
  
end