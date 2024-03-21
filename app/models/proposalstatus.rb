class Proposalstatus < ApplicationRecord
  has_many :proposals
  translates :name
  accepts_nested_attributes_for :translations, reject_if: proc { |x| x['name'].blank? }

  extend FriendlyId
  friendly_id :name_en, use: %i[slugged finders]

  def name_en
    name(:en)
  end

  def valid?
    slug != 'invalid'
  end
end
