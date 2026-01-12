<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineColumn from './PipelineColumn.vue';

const store = useStore();
const { t } = useI18n();

const conversationsByStage = computed(() => store.getters['pipeline/getConversationsByStage']);
const stages = computed(() => store.getters['pipeline/getStages']);
const isUpdating = computed(() => store.getters['pipeline/getUIFlags'].isUpdating);

const handleMove = async ({ conversation, fromStage, toStage }) => {
  try {
    await store.dispatch('pipeline/updateStage', {
      conversationId: conversation.display_id,
      stage: toStage,
      fromStage,
    });
  } catch (error) {
    // Show error notification
    console.error('Failed to move conversation:', error);
    // Optionally show a toast notification here
  }
};

const updateConversations = (stage, conversations) => {
  // This is called when dragging within the same column
  // We don't need to do anything here as vuedraggable handles it
};
</script>

<template>
  <div class="flex gap-4 h-full overflow-x-auto p-4">
    <div
      v-for="stage in stages"
      :key="stage"
      class="flex-shrink-0 w-80"
    >
      <PipelineColumn
        :stage="stage"
        :conversations="conversationsByStage[stage] || []"
        :is-updating="isUpdating"
        @update:conversations="conversations => updateConversations(stage, conversations)"
        @move="handleMove"
      />
    </div>
  </div>
</template>
