# app/models/life_goal.rb
class LifeGoal < ApplicationRecord
  belongs_to :user_response
  belongs_to :life_category

  validates :title, presence: true
  validates :description, presence: true

  # enum goal_type: { improvement: 0, maintenance: 1, new_habit: 2 }
  # enum status: { not_started: 0, in_progress: 1, completed: 2, paused: 3 }
  #
  enum :goal_type, [ :improvement, :maintenance, :new_habit ]
  enum :status, [ :not_started, :in_progress, :completed, :paused ]
end
