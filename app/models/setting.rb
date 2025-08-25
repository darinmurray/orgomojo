class Setting < ApplicationRecord
  belongs_to :user
  belongs_to :primary_wheel, class_name: 'Pie', optional: true

  validates :gender, presence: true
  validates :tone_1, presence: true
  validates :tone_2, presence: true
  validates :timespan, presence: true
  validates :pie_objective_length, numericality: { only_integer: true, greater_than: 0 }
  validates :slice_objective_length, numericality: { only_integer: true, greater_than: 0 }
  validates :slice_element_length, numericality: { only_integer: true, greater_than: 0 }
  validates :element_objective_length, numericality: { only_integer: true, greater_than: 0 }
  validates :task_length, numericality: { only_integer: true, greater_than: 0 }
  validates :task_outcome_length, numericality: { only_integer: true, greater_than: 0 }
end
