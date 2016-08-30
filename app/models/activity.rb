class Activity < ApplicationRecord
  include Rails.application.routes.url_helpers
  belongs_to :user
  belongs_to :ethtransaction
  belongs_to :item, polymorphic: true
  
  validates_presence_of :item_id, :item_type
  
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  
  def linked_name

    case item.class.to_s
    when 'Pledge'
      "<a href='/proposals/#{item.item.id}'>#{item.item.name}</a>"
    when 'NilClass'
      item_type.constantize.with_deleted.find(item_id).name
    else
      item.name
    end
  end
  #
  #   - if activity.item.class == NilClass
  #     = activity.item_type.constantize.with_deleted.find(activity.item_id).name
  #   - else
  #     - begin
  #       = link_to activity.item.name, activity.item, target: :_blank
  #     - rescue NoMethodError
  #       = activity.item.name
  # end

  def sentence
    if user_id == 0
      usertext= 'Somebody'
    elsif user.nil?
      usertext = 'Someone who does not exist with id ' + user_id.to_s
    else
      usertext = "#{user.display_name} (<a href='/users/#{user.slug}/activities'>#{user.display_name}</a>)"
    end
    if item.class == Proposal
      "#{usertext} #{description} <a href='/proposals/#{item.id}'>#{item.name}</a> #{extra_info}"
    elsif item.class == User
      "#{usertext} #{description} <a href='users/#{item.slug}'>#{item.name}</a> #{extra_info}"
    elsif item.class == Credit
      "#{usertext} #{description} <a href='credits/#{item.id}'>#{item.description}</a> and received  #{item.ethtransaction.value}#{ENV['currency_symbol']}"
    elsif item.class == NilClass
      dead_item = item_type.constantize.with_deleted.find(item_id) rescue 'something is not right here'
      "#{usertext} #{description} #{dead_item.description} and #{ethtransaction.value}#{ENV['currency_symbol']} were returned to the blockchain"
    else
      "#{usertext} #{description} <a href='/experiments/#{item.experiment.slug}/#{item.slug}'>#{item.name}</a> and received #{item.cost_bb}#{ENV['currency_symbol']}"    
    end
  end
  
  def value
    if item.class == Pledge
      item.pledge
    elsif ethtransaction
      ethtransaction.value
    else
      extra_info
    end
      
  end
  
end