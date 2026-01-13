import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import PipelineStagesHome from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/pipeline-stages'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'pipeline_stages_list',
          component: PipelineStagesHome,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
