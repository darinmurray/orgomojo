# app/models/life_category.rb
class LifeCategory < ApplicationRecord
  has_many :user_responses, dependent: :destroy
  has_many :life_goals, dependent: :destroy

  validates :name, presence: true
  validates :prompt_template, presence: true

  # Predefined life categories
  CATEGORIES = {
    "Health" => "Tell me what you like and don't like about the Health area of your life. Include physical fitness, nutrition, sleep, medical care, and overall wellbeing.",
    "Relationships" => "Tell me what you like and don't like about the Family and Friends area of your life. Include family relationships, friendships, social connections, and romantic relationships.",
    "Career" => "Tell me what you like and don't like about your Career/Work life. Include job satisfaction, professional growth, work-life balance, and career goals.",
    "Finances" => "Tell me what you like and don't like about your Financial situation. Include income, savings, debt, financial security, and money management.",
    "Personal_Growth" => "Tell me what you like and don't like about your Personal Development. Include learning, skills, hobbies, creativity, and self-improvement.",
    "Fun_Recreation" => "Tell me what you like and don't like about Fun and Recreation in your life. Include entertainment, hobbies, relaxation, and enjoyable activities.",
    "Physical_Environment" => "Tell me what you like and don't like about your Physical Environment. Include your home, neighborhood, workspace, and surroundings.",
    "Contribution" => "Tell me what you like and don't like about your Contribution to others. Include volunteering, helping others, community involvement, and making a difference."
  }.freeze

  def self.seed_categories
    CATEGORIES.each do |name, prompt|
      find_or_create_by(name: name) do |category|
        category.prompt_template = prompt
        category.description = "Life assessment for #{name.humanize} area"
      end
    end
  end
end
