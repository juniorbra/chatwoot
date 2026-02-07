<script setup>
import { computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const router = useRouter();
const route = useRoute();

const contactName = computed(
  () => props.conversation.contact?.name || 'Unknown Contact'
);
const contactEmail = computed(() => props.conversation.contact?.email);
const contactThumbnail = computed(() => props.conversation.contact?.thumbnail);
const inboxName = computed(
  () => props.conversation.inbox?.name || 'Unknown Inbox'
);
const assigneeName = computed(() => props.conversation.assignee?.name);
const assigneeAvatar = computed(() => props.conversation.assignee?.avatar_url);
const pipelineSummary = computed(() => props.conversation.pipeline_summary);

const lastActivityAt = computed(() => {
  try {
    const timestamp = props.conversation.last_activity_at;
    if (!timestamp) return 'No activity';
    return shortTimestamp(dynamicTime(timestamp));
  } catch (error) {
    console.error(
      'Error formatting timestamp:',
      error,
      props.conversation.last_activity_at
    );
    return 'Invalid date';
  }
});

const onCardClick = () => {
  const path = frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: props.conversation.id,
    })
  );
  router.push({ path });
};
</script>

<template>
  <div
    class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-3 cursor-grab active:cursor-grabbing hover:shadow-md transition-shadow"
    @click="onCardClick"
  >
    <!-- Header with contact info -->
    <div class="flex items-start gap-2 mb-2">
      <Avatar
        :name="contactName"
        :src="contactThumbnail"
        :size="32"
        rounded-full
      />
      <div class="flex-1 min-w-0">
        <div
          class="font-medium text-sm text-slate-900 dark:text-slate-25 truncate"
        >
          {{ contactName }}
        </div>
        <div
          v-if="contactEmail"
          class="text-xs text-slate-600 dark:text-slate-400 truncate"
        >
          {{ contactEmail }}
        </div>
      </div>
    </div>

    <!-- Summary -->
    <p
      v-if="pipelineSummary"
      class="text-xs text-slate-700 dark:text-slate-300 mb-2 line-clamp-3"
    >
      {{ pipelineSummary }}
    </p>

    <!-- Conversation details -->
    <div class="space-y-1.5 text-xs text-slate-600 dark:text-slate-400">
      <!-- Display ID and Inbox -->
      <div class="flex items-center gap-1.5">
        <Icon name="i-lucide-hash" class="size-3 flex-shrink-0" />
        <span class="truncate">{{ conversation.display_id }} • {{ inboxName }}</span>
      </div>

      <!-- Assignee -->
      <div v-if="assigneeName" class="flex items-center gap-1.5">
        <Avatar
          :name="assigneeName"
          :src="assigneeAvatar"
          :size="16"
          rounded-full
        />
        <span class="truncate">{{ assigneeName }}</span>
      </div>
      <div v-else class="flex items-center gap-1.5">
        <Icon name="i-lucide-user-x" class="size-3 flex-shrink-0" />
        <span>Unassigned</span>
      </div>

      <!-- Last activity -->
      <div class="flex items-center gap-1.5">
        <Icon name="i-lucide-clock" class="size-3 flex-shrink-0" />
        <span>{{ lastActivityAt }}</span>
      </div>
    </div>
  </div>
</template>
