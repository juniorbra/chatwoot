class PipelineStage < ApplicationRecord
  belongs_to :account

  validates :name, presence: true, length: { maximum: 50 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 6 }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true
  # validates :position, uniqueness: { scope: :account_id }

  default_scope { order(:position) }

  MAX_STAGES = 6

  after_destroy :reorder_positions

  private

  def reorder_positions
    account.pipeline_stages.reload.each_with_index do |stage, index|
      stage.update_column(:position, index) if stage.position != index
    end
  end
end
