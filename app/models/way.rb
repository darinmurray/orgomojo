class Way < ApplicationRecord
  belongs_to :user
  belongs_to :six_human_need

  validates :description, presence: true, length: { minimum: 2, maximum: 30 }

  scope :for_need, ->(need) { where(six_human_need: need) }
  scope :for_user, ->(user) { where(user: user) }
end
