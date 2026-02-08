<script setup>
import { computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const store = useStore();
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

const customAttributeDefinitions = computed(
  () => store.getters['pipeline/getCustomAttributeDefinitions']
);

const formatDate = value => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  const dd = String(date.getDate()).padStart(2, '0');
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const yyyy = date.getFullYear();
  return `${dd}-${mm}-${yyyy}`;
};

const formatValue = (value, type) => {
  if (type === 'date') return formatDate(value);
  return value;
};

const customAttributes = computed(() => {
  const attrs = props.conversation.custom_attributes || {};
  const definitions = customAttributeDefinitions.value || [];
  return definitions
    .filter(def => attrs[def.attribute_key] != null && attrs[def.attribute_key] !== '')
    .map(def => ({
      key: def.attribute_key,
      label: def.attribute_display_name,
      value: formatValue(attrs[def.attribute_key], def.attribute_display_type),
      type: def.attribute_display_type,
    }));
});

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
        <div class="flex items-center gap-1">
          <span
            class="font-medium text-sm text-slate-900 dark:text-slate-25 truncate"
          >
            {{ contactName }}
          </span>
          <CardPriorityIcon
            v-if="conversation.priority"
            :priority="conversation.priority"
            class="flex-shrink-0"
          />
        </div>
        <div
          v-if="contactEmail"
          class="text-xs text-slate-600 dark:text-slate-400 truncate"
        >
          {{ contactEmail }}
        </div>
      </div>
    </div>

    <!-- Custom Attributes -->
    <div
      v-if="customAttributes.length"
      class="mb-2 space-y-1 text-xs"
    >
      <div
        v-for="attr in customAttributes"
        :key="attr.key"
        class="flex items-center gap-1"
      >
        <span class="text-slate-500 dark:text-slate-400">{{ attr.label }}:</span>
        <span class="text-slate-800 dark:text-slate-200 truncate font-medium">{{ attr.value }}</span>
      </div>
    </div>

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
