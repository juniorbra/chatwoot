import ApiClient from './ApiClient';

class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('pipeline_stages', { accountScoped: true });
  }

  reorder(stages) {
    return this.axios.post(`${this.url}/reorder`, { stages });
  }
}

export default new PipelineStagesAPI();
