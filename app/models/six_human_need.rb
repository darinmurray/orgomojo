# app/models/six_human_need.rb
class SixHumanNeed < ApplicationRecord
  has_many :ways, dependent: :destroy
  has_many :users, through: :ways

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :order_position, presence: true, uniqueness: true,
            inclusion: { in: 1..6 }

  scope :ordered, -> { order(:order_position) }
end
