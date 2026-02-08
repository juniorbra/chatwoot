<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import PipelineCard from './PipelineCard.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
  conversations: {
    type: Array,
    default: () => [],
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:conversations', 'move']);

const { t } = useI18n();

const stageLabel = computed(() => props.stage.name);
const conversationCount = computed(() => props.conversations.length);

const localConversations = computed({
  get: () => props.conversations,
  set: value => emit('update:conversations', value),
});

const onMove = evt => {
  // In vuedraggable v4, the change event has a different structure
  // It can be 'added' or 'removed' events
  if (evt.added) {
    const { element, newIndex } = evt.added;
    const toStage = props.stage.id;

    // We need to get the fromStage from the element's metadata
    // The element should have the old stage info
    emit('move', {
      conversation: element,
      fromStage: element.pipeline_stage || null,
      toStage,
      newIndex,
    });
  }
};

const dragOptions = computed(() => ({
  animation: 200,
  group: 'conversations',
  disabled: props.isUpdating,
  ghostClass: 'opacity-50',
}));
</script>

<template>
  <div
    class="flex flex-col h-full min-h-0 bg-slate-50 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700"
  >
    <!-- Column Header -->
    <div
      class="p-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
    >
      <div class="flex items-center gap-2">
        <div
          class="w-3 h-3 rounded-full"
          :style="{ backgroundColor: stage.color }"
        />
        <h3 class="font-semibold text-slate-900 dark:text-slate-25">
          {{ stageLabel }}
        </h3>
      </div>
      <p class="text-xs text-slate-600 dark:text-slate-400 mt-1">
        {{
          conversationCount === 1
            ? t('PIPELINE.COLUMN.CONVERSATION', { count: conversationCount })
            : t('PIPELINE.COLUMN.CONVERSATIONS', { count: conversationCount })
        }}
      </p>
    </div>

    <!-- Draggable List -->
    <draggable
      v-model="localConversations"
      v-bind="dragOptions"
      :data-stage="stage"
      class="flex-1 p-2 overflow-y-auto space-y-2 min-h-[200px]"
      item-key="id"
      @change="onMove"
    >
      <template #item="{ element }">
        <PipelineCard :conversation="element" />
      </template>

      <!-- Empty State -->
      <template #footer>
        <div
          v-if="conversationCount === 0"
          class="flex items-center justify-center h-32 text-center"
        >
          <p class="text-sm text-slate-500 dark:text-slate-400">
            {{ t('PIPELINE.EMPTY_STATE.MESSAGE') }}
          </p>
        </div>
      </template>
    </draggable>

    <!-- Loading Overlay -->
    <div
      v-if="isUpdating"
      class="absolute inset-0 bg-white/50 dark:bg-slate-900/50 flex items-center justify-center rounded-lg"
    >
      <div
        class="w-8 h-8 border-4 border-woot-500 border-t-transparent rounded-full animate-spin"
      />
    </div>
  </div>
</template>
