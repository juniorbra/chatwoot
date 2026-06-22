class AddDescriptionToPipelineStages < ActiveRecord::Migration[7.1]
  def change
    add_column :pipeline_stages, :description, :text
  end
end
