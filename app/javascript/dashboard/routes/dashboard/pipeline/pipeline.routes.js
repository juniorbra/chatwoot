import { frontendURL } from 'dashboard/helper/URLHelper.js';
import PipelineView from './pages/PipelineView.vue';

const meta = {
  permissions: ['administrator', 'agent', 'custom_role'],
};

const pipelineRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/pipeline'),
      name: 'pipeline_index',
      meta,
      component: PipelineView,
    },
  ],
};

export default pipelineRoutes;
