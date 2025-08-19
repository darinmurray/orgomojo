class ExtractedDataPoint < ApplicationRecord
  belongs_to :chat_session

  validates :category, presence: true
  validates :value, presence: true

  CATEGORIES = %w[
    health_status
    tangible_goal
    intangible_goal
    current_state
    target_metrics
    timeline
    obstacles
    motivation
    support_system
    past_experience
  ].freeze

  DATA_TYPES = %w[
    text
    number
    date
    weight
    distance
    duration
    percentage
    boolean
    list
  ].freeze

  validates :category, inclusion: { in: CATEGORIES }
  validates :data_type, inclusion: { in: DATA_TYPES }, allow_blank: true

  scope :by_category, ->(category) { where(category: category) }
  scope :high_confidence, -> { where("confidence_score >= ?", 0.7) }

  def context_data
    context || {}
  end

  def set_context(key, value)
    current_context = context || {}
    current_context[key.to_s] = value
    update(context: current_context)
  end

  def formatted_value
    case data_type
    when "weight"
      "#{value} lbs"
    when "distance"
      "#{value} miles"
    when "percentage"
      "#{value}%"
    when "date"
      Date.parse(value).strftime("%B %d, %Y") rescue value
    else
      value
    end
  end

  def self.for_session_summary(chat_session)
    where(chat_session: chat_session)
      .high_confidence
      .group_by(&:category)
      .transform_values { |points| points.map(&:formatted_value).join(", ") }
  end
end
