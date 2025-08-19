# app/models/element.rb
class Element < ApplicationRecord
  belongs_to :pie_slice, class_name: "Slice", foreign_key: "slice_id", inverse_of: :elements

  validates :name, presence: true
  validates :completed, inclusion: { in: [ true, false ] }

  validates :priority, numericality: { only_integer: true }, allow_nil: true
  validates :time_needed, numericality: { only_integer: true }, allow_nil: true
  validates :time_scale, length: { maximum: 255 }, allow_nil: true
  after_initialize :set_default_time_scale, if: :new_record?


  validates :cadence, length: { maximum: 255 }, allow_nil: true
  # validates :deadline, allow_nil: true

  # ChatGPT of element language before saving
  before_save :create_an_objective_from_element
  before_save :rewrite_objective_if_done

  # Update slice percentage when element is saved
  after_save :update_slice_percentage
  after_destroy :update_slice_percentage

  # Allow controller to skip AI generation when handling custom word count
  def skip_ai_generation!
    @skip_ai_generation = true
  end

    private

  def set_default_time_scale
    self.time_scale ||= "minutes"
  end

  def update_slice_percentage
    # The percentage is now calculated dynamically, so no need to store it
    # But we could trigger other updates here if needed
  end

  # ChatGPT rewrite for tense
  def rewrite_objective_if_done
    if completed_changed?(from: false, to: true)
      self.objective = AiTextRewriter.new.rewrite(objective, target_tense: "past")
    end
  end

  # If the user submits an element with only the word 'help', trigger ChatGPT suggestion
  def create_an_objective_from_element
    if objective&.strip&.downcase == "help" && !@skip_ai_generation
      # Pass the entire element object so AI service can access slice name
      self.objective = AiTextRewriter.new.suggest_objective(self)
    end
  end
end
