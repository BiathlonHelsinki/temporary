class Question < ApplicationRecord
  has_many :answers
  belongs_to :page
  translates :question
  extend FriendlyId
  friendly_id :title_en , :use => [ :slugged, :finders, :history]
end