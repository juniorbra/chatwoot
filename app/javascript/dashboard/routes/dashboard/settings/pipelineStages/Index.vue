<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import PipelineStagesAPI from 'dashboard/api/pipelineStages';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const stages = ref([]);
const isLoading = ref(false);
const editingStage = ref(null);
const newStageName = ref('');
const newStageColor = ref('#3b82f6');
const isAddingStage = ref(false);

const canAddMore = computed(() => stages.value.length < 6);

const loadStages = async () => {
  isLoading.value = true;
  try {
    const response = await PipelineStagesAPI.get();
    stages.value = response.data;
  } catch (error) {
    useAlert(error.message);
  } finally {
    isLoading.value = false;
  }
};

const addStage = async () => {
  if (!newStageName.value.trim()) {
    useAlert('Please enter a stage name');
    return;
  }

  try {
    const response = await PipelineStagesAPI.create({
      pipeline_stage: {
        name: newStageName.value.trim(),
        position: stages.value.length,
        color: newStageColor.value,
      },
    });
    stages.value.push(response.data);
    newStageName.value = '';
    newStageColor.value = '#3b82f6';
    isAddingStage.value = false;
    useAlert('Pipeline stage added successfully');
  } catch (error) {
    useAlert(error.message);
  }
};

const startEdit = stage => {
  editingStage.value = { ...stage };
};

const cancelEdit = () => {
  editingStage.value = null;
};

const updateStage = async () => {
  try {
    const response = await PipelineStagesAPI.update(editingStage.value.id, {
      pipeline_stage: {
        name: editingStage.value.name,
        color: editingStage.value.color,
      },
    });
    const index = stages.value.findIndex(s => s.id === editingStage.value.id);
    if (index !== -1) {
      stages.value[index] = response.data;
    }
    editingStage.value = null;
    useAlert('Pipeline stage updated successfully');
  } catch (error) {
    useAlert(error.message);
  }
};

const deleteStage = async stageId => {
  // eslint-disable-next-line no-alert, no-restricted-globals
  if (!confirm('Are you sure you want to delete this pipeline stage?')) {
    return;
  }

  try {
    await PipelineStagesAPI.delete(stageId);
    stages.value = stages.value.filter(s => s.id !== stageId);
    useAlert('Pipeline stage deleted successfully');
  } catch (error) {
    useAlert(error.message);
  }
};

const reorderStages = async () => {
  try {
    const stagesData = stages.value.map((stage, index) => ({
      id: stage.id,
      position: index,
    }));
    const response = await PipelineStagesAPI.reorder(stagesData);
    stages.value = response.data;
    useAlert('Pipeline stages reordered successfully');
  } catch (error) {
    useAlert(error.message);
  }
};

const moveUp = async index => {
  if (index === 0) return;
  const temp = stages.value[index];
  stages.value[index] = stages.value[index - 1];
  stages.value[index - 1] = temp;
  await reorderStages();
};

const moveDown = async index => {
  if (index === stages.value.length - 1) return;
  const temp = stages.value[index];
  stages.value[index] = stages.value[index + 1];
  stages.value[index + 1] = temp;
  await reorderStages();
};

onMounted(() => {
  loadStages();
});
</script>

<template>
  <div class="flex-1 overflow-auto p-4">
    <BaseSettingsHeader
      title="Pipeline Stages"
      description="Configure the stages for your CRM pipeline. You can have up to 6 stages."
      :link-text="null"
    />

    <div class="max-w-4xl">
      <div v-if="isLoading" class="flex items-center justify-center py-8">
        <span class="text-slate-600">Loading...</span>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="(stage, index) in stages"
          :key="stage.id"
          class="flex items-center gap-4 p-4 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg"
        >
          <div class="flex items-center gap-2">
            <button
              type="button"
              class="p-1 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 disabled:opacity-50 disabled:cursor-not-allowed"
              :disabled="index === 0"
              @click="moveUp(index)"
            >
              <svg
                class="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 15l7-7 7 7"
                />
              </svg>
            </button>
            <button
              type="button"
              class="p-1 text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 disabled:opacity-50 disabled:cursor-not-allowed"
              :disabled="index === stages.length - 1"
              @click="moveDown(index)"
            >
              <svg
                class="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </button>
          </div>

          <div
            v-if="editingStage?.id === stage.id"
            class="flex-1 flex items-center gap-4"
          >
            <input
              v-model="editingStage.name"
              type="text"
              class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 rounded-lg focus:ring-2 focus:ring-woot-500 focus:border-transparent"
              placeholder="Stage name"
            />
            <input
              v-model="editingStage.color"
              type="color"
              class="w-12 h-10 rounded-lg border border-slate-300 cursor-pointer"
            />
            <Button
              solid
              blue
              sm
              @click="updateStage"
            >
              Save
            </Button>
            <Button
              outline
              slate
              sm
              @click="cancelEdit"
            >
              Cancel
            </Button>
          </div>

          <div v-else class="flex-1 flex items-center gap-4">
            <div
              class="w-4 h-4 rounded"
              :style="{ backgroundColor: stage.color }"
            />
            <span class="flex-1 font-medium text-slate-900 dark:text-slate-25">{{
              stage.name
            }}</span>
            <Button
              outline
              slate
              sm
              @click="startEdit(stage)"
            >
              Edit
            </Button>
            <Button
              v-if="stages.length > 1"
              outline
              ruby
              sm
              @click="deleteStage(stage.id)"
            >
              Delete
            </Button>
          </div>
        </div>

        <div
          v-if="isAddingStage"
          class="flex items-center gap-4 p-4 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg"
        >
          <div class="flex-1 flex items-center gap-4">
            <input
              v-model="newStageName"
              type="text"
              class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 rounded-lg focus:ring-2 focus:ring-woot-500 focus:border-transparent"
              placeholder="Stage name"
            />
            <input
              v-model="newStageColor"
              type="color"
              class="w-12 h-10 rounded-lg border border-slate-300 cursor-pointer"
            />
            <Button
              solid
              blue
              sm
              @click="addStage"
            >
              Add
            </Button>
            <Button
              outline
              slate
              sm
              @click="isAddingStage = false"
            >
              Cancel
            </Button>
          </div>
        </div>

        <Button
          v-if="!isAddingStage && canAddMore"
          icon="i-lucide-circle-plus"
          solid
          blue
          :disabled="!canAddMore"
          @click="isAddingStage = true"
        >
          Add Pipeline Stage
        </Button>

        <div v-if="!canAddMore" class="text-sm text-slate-600 dark:text-slate-400">
          Maximum of 6 pipeline stages reached
        </div>
      </div>
    </div>
  </div>
</template>
