<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineCard from './PipelineCard.vue';

const store = useStore();
const { t } = useI18n();

const byOutcome = computed(
  () => store.getters['pipeline/getConversationsByOutcome']
);
const won = computed(() => byOutcome.value.won || []);
const lost = computed(() => byOutcome.value.lost || []);
</script>

<template>
  <div class="h-full p-6">
    <div
      class="grid gap-4 h-full w-full mx-auto px-2 grid-cols-1 md:grid-cols-2"
    >
      <div class="flex flex-col min-h-0">
        <div
          class="flex flex-col h-full min-h-0 bg-slate-50 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <div
            class="p-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 flex items-center gap-2"
          >
            <h3 class="font-semibold text-slate-900 dark:text-slate-25">
              {{ t('PIPELINE.OUTCOME.WON') }}
            </h3>
            <span class="text-xs text-slate-500">{{ won.length }}</span>
          </div>
          <div class="flex-1 p-2 overflow-y-auto space-y-2 min-h-[200px]">
            <PipelineCard
              v-for="conversation in won"
              :key="conversation.id"
              :conversation="conversation"
            />
            <p
              v-if="won.length === 0"
              class="text-sm text-slate-500 dark:text-slate-400 text-center mt-8"
            >
              {{ t('PIPELINE.EMPTY_STATE.MESSAGE') }}
            </p>
          </div>
        </div>
      </div>

      <div class="flex flex-col min-h-0">
        <div
          class="flex flex-col h-full min-h-0 bg-slate-50 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <div
            class="p-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 flex items-center gap-2"
          >
            <h3 class="font-semibold text-slate-900 dark:text-slate-25">
              {{ t('PIPELINE.OUTCOME.LOST') }}
            </h3>
            <span class="text-xs text-slate-500">{{ lost.length }}</span>
          </div>
          <div class="flex-1 p-2 overflow-y-auto space-y-2 min-h-[200px]">
            <PipelineCard
              v-for="conversation in lost"
              :key="conversation.id"
              :conversation="conversation"
            />
            <p
              v-if="lost.length === 0"
              class="text-sm text-slate-500 dark:text-slate-400 text-center mt-8"
            >
              {{ t('PIPELINE.EMPTY_STATE.MESSAGE') }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
