# app/models/user_response.rb
class UserResponse < ApplicationRecord
  belongs_to :user
  belongs_to :life_category
  has_many :life_goals, dependent: :destroy

  validates :raw_response, presence: true

  # serialize :analysis_data, JSON
  # Remove the serialize line entirely and just use:
  # (Make sure your migration creates analysis_data as a json or text column)

  # enum status: { pending: 0, analyzed: 1, goals_created: 2 }
  enum :status, [ :pending, :analyzed, :goals_created ]
end
