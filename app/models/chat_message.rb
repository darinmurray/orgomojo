class ChatMessage < ApplicationRecord
  belongs_to :chat_session

  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  scope :user_messages, -> { where(role: "user") }
  scope :assistant_messages, -> { where(role: "assistant") }
  scope :chronological, -> { order(:created_at) }

  def user_message?
    role == "user"
  end

  def assistant_message?
    role == "assistant"
  end

  def has_audio?
    audio_file_path.present?
  end

  def audio_url
    return nil unless has_audio?
    # Assuming audio files are stored in public/audio or similar
    "/audio/#{File.basename(audio_file_path)}"
  end

  def message_metadata
    metadata || {}
  end

  def set_metadata(key, value)
    current_metadata = metadata || {}
    current_metadata[key.to_s] = value
    update(metadata: current_metadata)
  end
end
