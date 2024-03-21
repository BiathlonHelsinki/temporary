class PagesController < ApplicationController
  caches_page :show, expires_in: 1.year
  def show
    @page = Page.friendly.find(params[:id])
    set_meta_tags(title: @page.title)
    render(layout: 'home')
  end
end
