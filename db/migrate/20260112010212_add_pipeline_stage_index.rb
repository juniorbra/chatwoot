class AddPipelineStageIndex < ActiveRecord::Migration[7.1]
  def change
    # Add btree index for pipeline_stage queries on custom_attributes JSONB column
    # This optimizes filtering conversations by pipeline stage
    add_index :conversations, "(custom_attributes->>'pipeline_stage')",
              name: 'index_conversations_on_pipeline_stage',
              using: :btree
  end
end
