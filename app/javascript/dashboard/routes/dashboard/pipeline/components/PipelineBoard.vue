<script setup>
import { computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineColumn from './PipelineColumn.vue';

const store = useStore();
const { t } = useI18n();

const conversationsByStage = computed(
  () => store.getters['pipeline/getConversationsByStage']
);
const stages = computed(() => store.getters['pipeline/getStages']);
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
      class="grid gap-4 h-full max-w-7xl mx-auto"
      :class="{
        'grid-cols-1': stages.length === 1,
        'grid-cols-1 md:grid-cols-2': stages.length === 2,
        'grid-cols-1 md:grid-cols-2 lg:grid-cols-3': stages.length === 3,
        'grid-cols-1 md:grid-cols-2 lg:grid-cols-4': stages.length === 4,
        'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5':
          stages.length === 5,
        'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6':
          stages.length === 6,
      }"
    >
      <div v-for="stage in stages" :key="stage.id" class="flex flex-col h-full">
        <PipelineColumn
          :stage="stage"
          :conversations="conversationsByStage[stage.id] || []"
          :is-updating="isUpdating"
          @update:conversations="() => {}"
          @move="handleMove"
        />
      </div>
    </div>
  </div>
</template>
