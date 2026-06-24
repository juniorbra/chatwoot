/* global axios */
import ApiClient from './ApiClient';

class PipelineAPI extends ApiClient {
  constructor() {
    super('pipeline', { accountScoped: true });
  }

  get(status) {
    const params = status ? { status } : {};
    return axios.get(this.url, { params });
  }

  updateStage(conversationId, stage) {
    return axios.patch(`${this.url}/${conversationId}/update_stage`, { stage });
  }

  updateOutcome(conversationId, outcome) {
    return axios.patch(`${this.url}/${conversationId}/update_outcome`, {
      outcome,
    });
  }

  getClosed() {
    return axios.get(`${this.url}/closed`);
  }
}

export default new PipelineAPI();
