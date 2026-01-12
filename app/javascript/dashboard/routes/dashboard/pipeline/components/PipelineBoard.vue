<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineColumn from './PipelineColumn.vue';

const store = useStore();
useI18n();

const conversationsByStage = computed(
  () => store.getters['pipeline/getConversationsByStage']
);
const stages = computed(() => store.getters['pipeline/getStages'].slice(0, 4));
const isUpdating = computed(
  () => store.getters['pipeline/getUIFlags'].isUpdating
);

const handleMove = async ({ conversation, fromStage, toStage }) => {
  try {
    await store.dispatch('pipeline/updateStage', {
      conversationId: conversation.display_id,
      stage: toStage,
      fromStage,
    });
  } catch (error) {
    // Error handling is done by the API layer
  }
};
</script>

<template>
  <div class="flex-1 min-h-0 p-6">
    <div
      class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 h-full max-w-7xl mx-auto"
    >
      <div v-for="stage in stages" :key="stage" class="flex flex-col h-full">
        <PipelineColumn
          :stage="stage"
          :conversations="conversationsByStage[stage] || []"
          :is-updating="isUpdating"
          @update:conversations="() => {}"
          @move="handleMove"
        />
      </div>
    </div>
  </div>
</template>
