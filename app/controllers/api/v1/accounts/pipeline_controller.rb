class Api::V1::Accounts::PipelineController < Api::V1::Accounts::BaseController
  before_action :conversation, only: [:update_stage]

  def index
    @conversations_by_stage = {}

    Conversation::PIPELINE_STAGES.each do |stage|
      @conversations_by_stage[stage] = current_account
                                        .conversations
                                        .with_pipeline_stage(stage)
                                        .includes(:inbox, :contact, :assignee, :team)
                                        .order(last_activity_at: :desc)
                                        .limit(25)
    end

    render json: {
      conversations_by_stage: @conversations_by_stage.transform_values { |convs| convs.map { |c| conversation_json(c) } },
      stages: Conversation::PIPELINE_STAGES
    }
  end

  def update_stage
    stage = params[:stage]

    unless stage.nil? || Conversation::PIPELINE_STAGES.include?(stage)
      return render json: { error: "Invalid pipeline stage: #{stage}" }, status: :unprocessable_entity
    end

    @conversation.pipeline_stage = stage

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

  def conversation_json(conversation)
    {
      id: conversation.id,
      display_id: conversation.display_id,
      inbox_id: conversation.inbox_id,
      contact_id: conversation.contact_id,
      status: conversation.status,
      pipeline_stage: conversation.pipeline_stage,
      assignee_id: conversation.assignee_id,
      team_id: conversation.team_id,
      last_activity_at: conversation.last_activity_at,
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
      assignee: conversation.assignee ? {
        id: conversation.assignee.id,
        name: conversation.assignee.name,
        avatar_url: conversation.assignee.avatar_url
      } : nil,
      team: conversation.team ? {
        id: conversation.team.id,
        name: conversation.team.name
      } : nil
    }
  end
end
