require 'rails_helper'

RSpec.describe 'Pipeline API', type: :request do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:conversation1) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let!(:conversation2) { create(:conversation, account: account, inbox: inbox, contact: contact) }

  describe 'GET /api/v1/accounts/{account.id}/pipeline' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pipeline"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation1.update(custom_attributes: { 'pipeline_stage' => 'lead' })
        conversation2.update(custom_attributes: { 'pipeline_stage' => 'qualification' })
      end

      it 'returns all conversations grouped by pipeline stage' do
        get "/api/v1/accounts/#{account.id}/pipeline",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['stages']).to eq(Conversation::PIPELINE_STAGES)
        expect(json_response['conversations_by_stage']).to be_a(Hash)
        expect(json_response['conversations_by_stage']['lead'].length).to eq(1)
        expect(json_response['conversations_by_stage']['qualification'].length).to eq(1)
      end

      it 'returns empty arrays for stages without conversations' do
        get "/api/v1/accounts/#{account.id}/pipeline",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['conversations_by_stage']['proposal'].length).to eq(0)
        expect(json_response['conversations_by_stage']['negotiation'].length).to eq(0)
        expect(json_response['conversations_by_stage']['won'].length).to eq(0)
        expect(json_response['conversations_by_stage']['lost'].length).to eq(0)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/pipeline/:id/update_stage' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/pipeline/#{conversation1.display_id}/update_stage",
              params: { stage: 'lead' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates the pipeline stage of a conversation' do
        patch "/api/v1/accounts/#{account.id}/pipeline/#{conversation1.display_id}/update_stage",
              headers: agent.create_new_auth_token,
              params: { stage: 'lead' },
              as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['conversation']['pipeline_stage']).to eq('lead')
        expect(conversation1.reload.pipeline_stage).to eq('lead')
      end

      it 'returns error for invalid pipeline stage' do
        patch "/api/v1/accounts/#{account.id}/pipeline/#{conversation1.display_id}/update_stage",
              headers: agent.create_new_auth_token,
              params: { stage: 'invalid_stage' },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)

        expect(json_response['error']).to include('Invalid pipeline stage')
      end

      it 'allows clearing pipeline stage with nil' do
        conversation1.update(custom_attributes: { 'pipeline_stage' => 'lead' })

        patch "/api/v1/accounts/#{account.id}/pipeline/#{conversation1.display_id}/update_stage",
              headers: agent.create_new_auth_token,
              params: { stage: nil },
              as: :json

        expect(response).to have_http_status(:success)
        expect(conversation1.reload.pipeline_stage).to be_nil
      end

      it 'returns not found for non-existent conversation' do
        patch "/api/v1/accounts/#{account.id}/pipeline/999999/update_stage",
              headers: agent.create_new_auth_token,
              params: { stage: 'lead' },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
