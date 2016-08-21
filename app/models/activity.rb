class Activity < ApplicationRecord
  include Rails.application.routes.url_helpers
  belongs_to :user
  belongs_to :ethtransaction
  belongs_to :item, polymorphic: true
  
  validates_presence_of :item_id, :item_type
  
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  
  def sentence
    if user_id == 0
      usertext= 'Somebody'
    elsif user.nil?
      usertext = 'Someone who does not exist with id ' + user_id.to_s
    else
      usertext = "#{user.name} (<a href='/users/#{user.slug}/activities'>#{user.username}</a>)"
    end
    if item.class == Proposal
      "#{usertext} #{description} <a href='/proposals/#{item.id}'>#{item.name}</a>"
    elsif item.class == User
      "#{usertext} #{description} <a href='users/#{item.slug}'>#{item.name}</a> #{extra_info}"
    else
      "#{usertext} #{description} the #{item_type.downcase} <a href='/experiments/#{item.slug}'>#{item.name}</a> and received #{item.cost_bb}#{ENV['currency_symbol']}"    
    end
  end
  
end
