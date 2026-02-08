<script setup>
import { onMounted, computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineBoard from '../components/PipelineBoard.vue';

const store = useStore();
const { t } = useI18n();

const statusFilter = ref('');

const statusOptions = [
  { value: '', label: t('PIPELINE.FILTERS.ALL_ACTIVE') },
  { value: 'open', label: t('PIPELINE.FILTERS.OPEN') },
  { value: 'pending', label: t('PIPELINE.FILTERS.PENDING') },
  { value: 'snoozed', label: t('PIPELINE.FILTERS.SNOOZED') },
  { value: 'resolved', label: t('PIPELINE.FILTERS.RESOLVED') },
];

const isLoading = computed(
  () => store.getters['pipeline/getUIFlags'].isFetching
);

const fetchPipeline = async () => {
  try {
    await store.dispatch('pipeline/get', statusFilter.value);
  } catch (error) {
    console.error('Error loading pipeline:', error);
  }
};

const onStatusChange = event => {
  statusFilter.value = event.target.value;
  fetchPipeline();
};

onMounted(fetchPipeline);
</script>

<template>
  <div class="flex flex-col h-full bg-slate-25 dark:bg-slate-900">
    <!-- Header -->
    <div
      class="flex items-center justify-between p-4 bg-white dark:bg-slate-800 border-b border-slate-75 dark:border-slate-700"
    >
      <div>
        <h1 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
          {{ t('PIPELINE.HEADER') }}
        </h1>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
          {{ t('PIPELINE.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <label
          class="text-sm text-slate-600 dark:text-slate-400"
          for="pipeline-status-filter"
        >
          {{ t('PIPELINE.FILTERS.STATUS') }}:
        </label>
        <select
          id="pipeline-status-filter"
          :value="statusFilter"
          class="text-sm rounded-lg border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-800 dark:text-slate-100 px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-woot-500"
          @change="onStatusChange"
        >
          <option
            v-for="option in statusOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center h-full">
      <div class="text-center">
        <div
          class="w-16 h-16 border-4 border-woot-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"
        />
        <p class="text-slate-600 dark:text-slate-400">
          {{ t('PIPELINE.LOADING') }}
        </p>
      </div>
    </div>

    <!-- Pipeline Board -->
    <div v-else class="flex-1 overflow-hidden">
      <PipelineBoard />
    </div>
  </div>
</template>
