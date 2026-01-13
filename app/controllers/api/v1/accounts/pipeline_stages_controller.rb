class Api::V1::Accounts::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_pipeline_stage, only: [:update, :destroy]

  def index
    @pipeline_stages = current_account.pipeline_stages.order(:position)
    render json: @pipeline_stages
  end

  def create
    @pipeline_stage = current_account.pipeline_stages.new(pipeline_stage_params)

    if current_account.pipeline_stages.count >= PipelineStage::MAX_STAGES
      return render json: { error: "Maximum of #{PipelineStage::MAX_STAGES} stages allowed" }, status: :unprocessable_entity
    end

    if @pipeline_stage.save
      render json: @pipeline_stage, status: :created
    else
      render json: { errors: @pipeline_stage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @pipeline_stage.update(pipeline_stage_params)
      render json: @pipeline_stage
    else
      render json: { errors: @pipeline_stage.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if current_account.pipeline_stages.count <= 1
      return render json: { error: 'Cannot delete the last pipeline stage' }, status: :unprocessable_entity
    end

    @pipeline_stage.destroy
    head :no_content
  end

  def reorder
    stages_params = params.require(:stages)

    ActiveRecord::Base.transaction do
      stages_params.each_with_index do |stage_data, index|
        stage = current_account.pipeline_stages.find(stage_data[:id])
        stage.update!(position: index)
      end
    end

    @pipeline_stages = current_account.pipeline_stages.order(:position)
    render json: @pipeline_stages
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Pipeline stage not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def check_authorization
    authorize current_account, :update?
  end

  def set_pipeline_stage
    @pipeline_stage = current_account.pipeline_stages.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Pipeline stage not found' }, status: :not_found
  end

  def pipeline_stage_params
    params.require(:pipeline_stage).permit(:name, :position, :color)
  end
end
