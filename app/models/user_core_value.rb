class UserCoreValue < ApplicationRecord
  belongs_to :user
  belongs_to :core_value

  # Ensure a user can't select the same core value twice
  validates :user_id, uniqueness: { scope: :core_value_id }

  # Validate importance level is within acceptable range
  validates :importance_level, presence: true,
            inclusion: { in: 1..10, message: "must be between 1 and 10" }

  # Optional scope to order by importance
  scope :by_importance, -> { order(importance_level: :desc) }
  scope :most_important, -> { where("importance_level >= ?", 8) }
end
