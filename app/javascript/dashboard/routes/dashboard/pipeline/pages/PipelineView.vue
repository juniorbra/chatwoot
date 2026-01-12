<script setup>
import { ref, onMounted, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

const store = useStore();
const { t } = useI18n();

const isLoading = computed(() => store.getters['pipeline/getUIFlags'].isFetching);
const conversationsByStage = computed(() => store.getters['pipeline/getConversationsByStage']);
const stages = computed(() => store.getters['pipeline/getStages']);

onMounted(async () => {
  await store.dispatch('pipeline/get');
});
</script>

<template>
  <div class="flex flex-col h-full bg-slate-25 dark:bg-slate-900">
    <!-- Header -->
    <div class="flex items-center justify-between p-4 bg-white dark:bg-slate-800 border-b border-slate-75 dark:border-slate-700">
      <div>
        <h1 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
          {{ t('PIPELINE.HEADER') }}
        </h1>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
          {{ t('PIPELINE.DESCRIPTION') }}
        </p>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center h-full">
      <div class="text-center">
        <div class="w-16 h-16 border-4 border-woot-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
        <p class="text-slate-600 dark:text-slate-400">{{ t('PIPELINE.LOADING') }}</p>
      </div>
    </div>

    <!-- Pipeline Board Placeholder -->
    <div v-else class="flex-1 overflow-x-auto p-4">
      <div class="flex gap-4 min-h-full">
        <div
          v-for="stage in stages"
          :key="stage"
          class="flex-shrink-0 w-80 bg-white dark:bg-slate-800 rounded-lg border border-slate-75 dark:border-slate-700 flex flex-col"
        >
          <!-- Column Header -->
          <div class="p-4 border-b border-slate-75 dark:border-slate-700">
            <h3 class="font-semibold text-slate-900 dark:text-slate-25">
              {{ t(`PIPELINE.STAGES.${stage.toUpperCase()}`) }}
            </h3>
            <span class="text-sm text-slate-600 dark:text-slate-400">
              {{ (conversationsByStage[stage] || []).length }} conversations
            </span>
          </div>

          <!-- Column Content -->
          <div class="flex-1 p-2 overflow-y-auto">
            <div v-if="(conversationsByStage[stage] || []).length === 0" class="text-center py-8 text-slate-500 dark:text-slate-400">
              <p class="text-sm">{{ t('PIPELINE.EMPTY_STATE.MESSAGE') }}</p>
            </div>
            <div v-else class="space-y-2">
              <div
                v-for="conversation in conversationsByStage[stage]"
                :key="conversation.id"
                class="p-3 bg-slate-25 dark:bg-slate-700 rounded border border-slate-75 dark:border-slate-600 hover:border-woot-500 dark:hover:border-woot-500 cursor-move transition-colors"
              >
                <div class="font-medium text-sm text-slate-900 dark:text-slate-25">
                  {{ conversation.contact?.name || 'Unknown' }}
                </div>
                <div class="text-xs text-slate-600 dark:text-slate-400 mt-1">
                  #{{ conversation.display_id }} • {{ conversation.inbox?.name }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
