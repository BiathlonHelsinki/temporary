class PagesController < ApplicationController
  
  def show
    @page = Page.friendly.find(params[:id])
    render layout: 'home'
  end
  
end