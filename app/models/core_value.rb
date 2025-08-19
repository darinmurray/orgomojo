class CoreValue < ApplicationRecord
  validates :name, presence: true

  # Association with users through join table
  has_many :user_core_values, dependent: :destroy
  has_many :users, through: :user_core_values
end
