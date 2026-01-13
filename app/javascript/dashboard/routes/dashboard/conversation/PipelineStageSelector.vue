<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

export default {
  components: {
    MultiselectDropdown,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      pipelineStages: [
        {
          id: null,
          name: this.$t('PIPELINE.STAGES.NONE'),
        },
        {
          id: 'lead',
          name: this.$t('PIPELINE.STAGES.LEAD'),
        },
        {
          id: 'qualification',
          name: this.$t('PIPELINE.STAGES.QUALIFICATION'),
        },
        {
          id: 'proposal',
          name: this.$t('PIPELINE.STAGES.PROPOSAL'),
        },
        {
          id: 'negotiation',
          name: this.$t('PIPELINE.STAGES.NEGOTIATION'),
        },
        {
          id: 'won',
          name: this.$t('PIPELINE.STAGES.WON'),
        },
        {
          id: 'lost',
          name: this.$t('PIPELINE.STAGES.LOST'),
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    assignedPipelineStage: {
      get() {
        const currentStage =
          this.currentChat?.custom_attributes?.pipeline_stage;
        const selectedOption = this.pipelineStages.find(
          opt => opt.id === currentStage
        );
        return selectedOption || this.pipelineStages[0];
      },
      set(stageItem) {
        const stage = stageItem ? stageItem.id : null;
        const fromStage = this.currentChat?.custom_attributes?.pipeline_stage;

        this.$store
          .dispatch('pipeline/updateStage', {
            conversationId: this.conversationId,
            stage,
            fromStage,
          })
          .then(() => {
            // Update the current conversation in the store with the new pipeline stage
            if (this.currentChat && this.currentChat.id) {
              const updatedChat = {
                ...this.currentChat,
                custom_attributes: {
                  ...this.currentChat.custom_attributes,
                  pipeline_stage: stage,
                },
              };
              this.$store.commit('UPDATE_CONVERSATION', updatedChat);
            }

            const stageName = stageItem
              ? stageItem.name
              : this.$t('PIPELINE.STAGES.NONE');
            useAlert(
              this.$t('PIPELINE.API.SUCCESS_MESSAGE', {
                stage: stageName,
              })
            );
          })
          .catch(error => {
            console.error('Error updating pipeline stage:', error);
            useAlert(error.message || this.$t('PIPELINE.API.ERROR_MESSAGE'));
          });
      },
    },
  },
  methods: {
    onClickAssignStage(selectedStageItem) {
      const isSameStage =
        this.assignedPipelineStage &&
        this.assignedPipelineStage.id === selectedStageItem.id;

      this.assignedPipelineStage = isSameStage ? null : selectedStageItem;
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <MultiselectDropdown
      :options="pipelineStages"
      :selected-item="assignedPipelineStage"
      :multiselector-title="
        $t('CONVERSATION_SIDEBAR.ACCORDION.PIPELINE_STAGE')
      "
      :multiselector-placeholder="$t('PIPELINE.SELECT_PLACEHOLDER')"
      :no-search-result="$t('PIPELINE.NO_RESULTS')"
      :input-placeholder="$t('PIPELINE.INPUT_PLACEHOLDER')"
      @select="onClickAssignStage"
    />
  </div>
</template>
