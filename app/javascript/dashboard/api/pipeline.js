/* global axios */
import ApiClient from './ApiClient';

class PipelineAPI extends ApiClient {
  constructor() {
    super('pipeline', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  updateStage(conversationId, stage) {
    return axios.patch(`${this.url}/${conversationId}/update_stage`, { stage });
  }
}

export default new PipelineAPI();
