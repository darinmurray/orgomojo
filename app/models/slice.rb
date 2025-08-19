# app/models/slice.rb
class Slice < ApplicationRecord
  belongs_to :pie
  has_many :elements, foreign_key: "slice_id", dependent: :destroy, inverse_of: :pie_slice

  validates :name, presence: true
  validates :color, presence: true

  accepts_nested_attributes_for :elements, allow_destroy: true, reject_if: :all_blank


def slice_params
  params.require(:slice).permit(:name, :target_percentage, :objective)
end


  # Calculate percentage based on completed elements
  def calculated_percentage
    return 0 if elements.empty?

    completed_count = elements.where(completed: true).count
    total_count = elements.count

    ((completed_count.to_f / total_count) * 100).round
  end

  # Use calculated percentage if elements exist, otherwise use stored percentage
  def percentage
    if elements.any?
      calculated_percentage
    else
      read_attribute(:percentage) || 0
    end
  end

  # Allow setting percentage (will be overridden by calculated when elements exist)
  def percentage=(value)
    write_attribute(:percentage, value.to_i)
  end
end
