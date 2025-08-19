class ChatSession < ApplicationRecord
  belongs_to :user
  has_many :chat_messages, dependent: :destroy
  has_many :extracted_data_points, dependent: :destroy

  enum :status, { active: 0, completed: 1, paused: 2 }

  validates :status, presence: true

  after_create :set_default_title

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  def conversation_data
    conversation_state || {}
  end

  def update_conversation_state(key, value)
    current_state = conversation_state || {}
    current_state[key.to_s] = value
    update(conversation_state: current_state)
  end

  def get_conversation_state(key)
    conversation_data[key.to_s]
  end

  def latest_message
    chat_messages.order(:created_at).last
  end

  def messages_count
    chat_messages.count
  end

  def completion_percentage
    required_data_points = %w[health_status tangible_goal intangible_goal current_state target_metrics]
    extracted_categories = extracted_data_points.pluck(:category).uniq

    completed = required_data_points.count { |category| extracted_categories.include?(category) }
    (completed.to_f / required_data_points.length * 100).round
  end

  def mark_completed!
    update!(status: "completed", completed_at: Time.current)
  end

  def ready_for_completion?
    completion_percentage >= 80
  end

  def display_title
    title.presence || "Health Conversation ##{id}"
  end

  private

  def set_default_title
    update_column(:title, "Health Conversation ##{id}") if title.blank?
  end
end
