class AddDefaultPipelineStages < ActiveRecord::Migration[7.1]
  def up
    default_stages = [
      { name: 'Lead', color: '#6b7280' },
      { name: 'Qualification', color: '#3b82f6' },
      { name: 'Proposal', color: '#f59e0b' },
      { name: 'Negotiation', color: '#8b5cf6' }
    ]

    Account.find_each do |account|
      default_stages.each_with_index do |stage, index|
        account.pipeline_stages.create!(
          name: stage[:name],
          position: index,
          color: stage[:color]
        )
      end
    end
  end

  def down
    PipelineStage.delete_all
  end
end
