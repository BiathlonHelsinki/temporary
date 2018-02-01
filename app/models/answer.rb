class Answer < ApplicationRecord
  belongs_to :question
  translates :body, :contributor_type, :contributor_id
  has_many :comments, as: :item

end