# app/models/pie.rb (update to include elements in nested attributes)
class Pie < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :slices, dependent: :destroy
  has_many :elements, through: :slices

  validates :name, presence: true

  accepts_nested_attributes_for :slices, allow_destroy: true, reject_if: :all_blank

  # Ensure we always have at least one slice after saving
  after_save :ensure_slices_exist

  private

  def ensure_slices_exist
    if slices.empty?
      slices.create!(name: "Slice 1", color: "#90EE90")
    end
  end
end
