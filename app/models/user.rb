class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :pies, dependent: :destroy
  has_one :setting, dependent: :destroy
  has_many :ways, dependent: :destroy
  has_many :six_human_needs, through: :ways
  has_many :chat_sessions, dependent: :destroy

    # for anthropic chat
    # This allows users to have multiple responses to life goals
    # and associate them with different chat sessions or contexts
    # This is useful for tracking user progress and responses over time
    # and allows for more flexible interactions with the AI.
    has_many :user_responses, dependent: :destroy
  has_many :life_goals, through: :user_responses

  # Core Values association
  has_many :user_core_values, dependent: :destroy
  has_many :core_values, through: :user_core_values


  def self.from_omniauth(auth)
    user = where(email: auth.info.email).first_or_initialize do |new_user|
      new_user.email = auth.info.email
      new_user.provider = auth.provider
      new_user.uid = auth.uid
      new_user.password = Devise.friendly_token[0, 20]
    end

    # Always update these fields (for both new and existing users)
    full_name = auth.info.name || ""
    name_parts = full_name.split(" ")
    user.firstname = name_parts.first || ""
    user.lastname = name_parts[1..-1].join(" ") || ""
    user.photo = auth.info.image

    user.save!
    user
  end

  # Automatically create a setting for each new user
  after_create :create_default_setting
  after_create :create_default_ways

  def create_default_setting
    create_setting
  end

  def create_default_ways
    # Create a default way for each of the six human needs
    SixHumanNeed.ordered.each do |need|
      ways.create!(
        six_human_need: need,
        description: "Add your personal way of meeting the need for #{need.name.downcase}..."
      )
    end
  end
end

# OAuth clinet ID and secret should be set in environment variables
# 617847518582-1o9qg4dl58oarl6bs8r45m025avjqo3l.apps.googleusercontent.com
