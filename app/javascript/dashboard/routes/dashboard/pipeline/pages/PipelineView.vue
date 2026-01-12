<script setup>
import { onMounted, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineBoard from '../components/PipelineBoard.vue';

const store = useStore();
const { t } = useI18n();

const isLoading = computed(() => store.getters['pipeline/getUIFlags'].isFetching);

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

    <!-- Pipeline Board -->
    <div v-else class="flex-1 overflow-hidden">
      <PipelineBoard />
    </div>
  </div>
</template>
