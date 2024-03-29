class Activity < ApplicationRecord
  include PgSearch
  pg_search_scope :search_activity_feed, against: [:description], associated_against: { user: %i[name username], ethtransaction: :txaddress }

  include Rails.application.routes.url_helpers
  belongs_to :contributor, polymorphic: true
  belongs_to :user
  belongs_to :ethtransaction
  belongs_to :blockchain_transaction
  belongs_to :item, polymorphic: true
  belongs_to :extra, polymorphic: true
  belongs_to :onetimer
  has_one :instances_user
  validates_presence_of :item_id, :item_type

  scope :by_user, ->(user_id) { where(user_id:) }
  scope :temporary, -> { where("id <= 6705") }
  scope :kuusipalaa, -> { where("id > 6705") }

  def linked_name
    case item.class.to_s
    when 'Idea'
      "<a href='https://kuusipalaa.fi/ideas/#{item.slug}' target='_blank'>#{item.name}</a>"
    when 'Question'
      "<a href='https://kuusipalaa.fi/pages/#{item.page.slug}' target='_blank'>#{item.question}</a>"
    when 'Answer'
      "<a href='https://kuusipalaa.fi/pages/#{item.question.page.slug}' target='_blank'>#{item.question.question}</a>"
    when 'Meeting'
      "<a href='https://kuusipalaa.fi/meetings/#{item.slug}' target='_blank'>#{item.name}</a>"
    when 'Credit'
      item.name
    when 'Stake'
      item.amount.to_s + ' stake' + (item.amount > 1 ? 's' : '')
    when 'Group'
      "<a href='https://kuusipalaa.fi/groups/#{item.slug}' target='_blank'>#{item.display_name}</a>"
    when 'Comment'
      if item.root_comment.era_id == 1
        "<a href='/posts/#{item.root_comment.slug}'>#{item.root_comment.name}</a>"
      elsif item.root_comment.era_id == 2
        "<a href='https://kuusipalaa.fi/#{item.root_comment.class.to_s.tableize}/#{item.root_comment.slug}' target='_blank'>#{item.root_comment.name}</a>"
      end
    when 'Pledge'
      if item.item.class == Proposal
        "<a href='/proposals/#{item.item.id}'>#{item.item.name}</a>"
      elsif item.item.class == Idea
        "<a href='http://kuusipalaa.fi/ideas/#{item.item.slug}'>#{item.item.name}</a>"
      end
    when 'Proposal'
      out = "<a href='/proposals/#{item.id}'>#{item.name}</a>"
      out += extra_info if description =~ /status/ && description =~ /changed/
      out
    when 'NilClass'
      if item_type == 'Nfc'
        'erased an ID card'
      elsif item_type == 'Member'
        "<a href='https://kuusipalaa.fi/groups/#{extra.slug}' target='_blank'>#{extra.long_name}</a>" if extra.class == Group
      else
        begin
          item_type.constantize.with_deleted.find(item_id).name
        rescue StandardError
          ''
        end
      end
    when 'Userphotoslot'
      I18n.t(:used_on_event, instance: "<a href='/events/#{item.userphoto.instance.event.slug}/#{item.userphoto.instance.slug}'>#{item.userphoto.instance.name}</a>") if !item.userphoto.nil? && item.userphoto.instance
    when 'Roombooking'
      ("<a href='/roombookings/'>#{item.day.strftime('%-d %B %Y')}</a> " + extra_info.to_s) || ''
    when 'User'

      if value
        if description == 'received_from' && contributor != item
          "<a href='https://kuusipalaa.fi/users/#{item.slug}'>#{item.display_name}</a> #{I18n.t(:on_behalf_of)} <a href='https://kuusipalaa.fi/groups/#{contributor.slug}'>#{contributor.display_name}</a><br /><small>#{extra_info}</small>"
        else
          "#{item.display_name}  <br /><small>#{extra_info}</small>"
        end
      elsif extra
        "<a href='/users/" + item.slug + "'>" + item.display_name + "</a> #{I18n.t(extra_info.to_sym)} <a href='/" + extra.class.table_name + "/#{extra.id}'>" + extra.name + "</a>"
      elsif description =~ /joined/
        ''
      else
        "<a href='/users/" + item.slug + "'>" + item.display_name + "</a>"

      end
    when 'Instance'
      if item.start_at > '2018-01-01'.to_date
        if item.open_time == true
          item.name
        else
          "<a href='https://kuusipalaa.fi/events/#{item.event.slug}/#{item.slug}'>#{item.name}</a>"
        end
      else
        "<a href='/events/#{item.event.slug}/#{item.slug}'>#{item.name}</a>"
      end
    when 'Nfc'
      "an ID card"
    when 'Post'
      if item.era_id == 1

        "<a href='/posts/#{item.slug}'>by the #{ENV['currency_symbol']}empsBot</a>"

      else
        "<a href='https://kuusipalaa.fi/posts/#{item.root_comment.slug}' target='_blank'>#{item.root_comment.name}</a>"
      end
    when 'Event'
      if item.start_at > '2018-01-01'.to_date
        "https://kuusipalaa.fi/<a href='/experiments/#{item.slug}'>#{item.name}</a>"
      else
        "<a href='/experiments/#{item.slug}'>#{item.name}</a>"
      end
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
    usertext = if user_id == 0
      'Somebody'
    elsif user.nil?
      'Someone who does not exist with id ' + user_id.to_s
    else
      "#{user.display_name} (<a href='/users/#{user.slug}/activities'>#{user.display_name}</a>)"
    end
    if item.class == Proposal
      "#{usertext} #{description} <a href='/proposals/#{item.id}'>#{item.name}</a> #{extra_info}"
    elsif item.class == User
      "#{usertext} #{description} <a href='users/#{item.slug}'>#{item.name}</a> #{extra_info}"
    elsif item.class == Credit
      if blockchain_transaction
        "#{usertext} #{description} <a href='credits/#{item.id}'>#{item.description}</a> and received  #{blockchain_transaction.value}#{ENV['currency_symbol']}"
      else
        "#{usertext} #{description} <a href='credits/#{item.id}'>#{item.description}</a> and received  #{item.value}#{ENV['currency_symbol']}"
      end
    elsif item.class == NilClass
      dead_item = begin
        item_type.constantize.with_deleted.find(item_id)
      rescue StandardError
        'something is not right here'
      end
      "#{usertext} #{description} #{dead_item.description} and #{dead_item.value}#{ENV['currency_symbol']} were returned to the blockchain"
    elsif item.class == Pledge
      "#{usertext} #{description} #{linked_name} #{extra_info}"
    elsif item.class == Post
      "#{usertext} #{description} by the TempsBot"
    elsif item.class == Roombooking
      "#{usertext} #{description}"
    elsif item.class == Userphotoslot
      "#{usertext} #{description}"
    elsif item.class == Event
      "#{usertext} #{description}"
    else
      "#{usertext} #{description} <a href='/events/#{item.event.slug}/#{item.slug}'>#{item.name}</a> and received #{item.cost_bb}#{ENV['currency_symbol']}"
    end
  end

  def value
    if item.class == Pledge
      item.pledge.to_i
    elsif blockchain_transaction
      blockchain_transaction.value.to_i
    elsif ethtransaction
      ethtransaction.value.to_i
    elsif extra.nil? && (description !~ /changed/ && description !~ /status/)
      extra_info
    else
      nil
    end
  end
end
