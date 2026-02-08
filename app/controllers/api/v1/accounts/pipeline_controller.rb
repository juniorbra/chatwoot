class Api::V1::Accounts::PipelineController < Api::V1::Accounts::BaseController
  before_action :conversation, only: [:update_stage]

  def index
    @conversations_by_stage = {}
    @stages = current_account.pipeline_stages.order(:position)

    @stages.each do |stage|
      scope = current_account.conversations.with_pipeline_stage(stage.id)
      scope = apply_status_filter(scope)
      @conversations_by_stage[stage.id.to_s] = scope
                                               .includes(:inbox, :contact, :assignee, :team)
                                               .order(last_activity_at: :desc)
                                               .limit(25)
    end

    render json: {
      conversations_by_stage: @conversations_by_stage.transform_values { |convs| convs.map { |c| conversation_json(c) } },
      stages: @stages.as_json(only: [:id, :name, :position, :color])
    }
  end

  def update_stage
    stage_id = params[:stage]

    unless stage_id.nil?
      stage = current_account.pipeline_stages.find_by(id: stage_id)
      return render json: { error: "Invalid pipeline stage: #{stage_id}" }, status: :unprocessable_entity unless stage
    end

    @conversation.pipeline_stage = stage_id
    @conversation.pipeline_summary = params[:summary] if params.key?(:summary)

    if @conversation.save
      render json: { conversation: conversation_json(@conversation) }
    else
      render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:id])
    render_not_found_error('Conversation') unless @conversation
  end

  def apply_status_filter(scope)
    status = params[:status]
    valid_statuses = Conversation.statuses.keys

    if status.present? && valid_statuses.include?(status)
      scope.where(status: status)
    else
      scope.where.not(status: :resolved)
    end
  end

  def conversation_json(conversation)
    {
      id: conversation.id,
      display_id: conversation.display_id,
      inbox_id: conversation.inbox_id,
      contact_id: conversation.contact_id,
      status: conversation.status,
      pipeline_stage: conversation.pipeline_stage,
      pipeline_summary: conversation.pipeline_summary,
      assignee_id: conversation.assignee_id,
      team_id: conversation.team_id,
      last_activity_at: conversation.last_activity_at&.to_i,
      contact: {
        id: conversation.contact.id,
        name: conversation.contact.name,
        email: conversation.contact.email,
        phone_number: conversation.contact.phone_number,
        thumbnail: conversation.contact.avatar_url
      },
      inbox: {
        id: conversation.inbox.id,
        name: conversation.inbox.name,
        channel_type: conversation.inbox.channel_type
      },
      assignee: if conversation.assignee
                  {
                    id: conversation.assignee.id,
                    name: conversation.assignee.name,
                    avatar_url: conversation.assignee.avatar_url
                  }
                end,
      team: if conversation.team
              {
                id: conversation.team.id,
                name: conversation.team.name
              }
            end
    }
  end
end
