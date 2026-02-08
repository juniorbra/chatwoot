import types from '../mutation-types';
import PipelineAPI from '../../api/pipeline';

export const state = {
  conversationsByStage: {},
  stages: [],
  statusFilter: '',
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

export const getters = {
  getConversationsByStage(_state) {
    return _state.conversationsByStage;
  },
  getStages(_state) {
    return _state.stages;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getConversationsByStageId: _state => stageId => {
    return _state.conversationsByStage[stageId] || [];
  },
  getStatusFilter(_state) {
    return _state.statusFilter;
  },
};

export const actions = {
  get: async function getPipelineConversations({ commit }, status = '') {
    commit(types.SET_PIPELINE_UI_FLAG, { isFetching: true });
    commit(types.SET_PIPELINE_STATUS_FILTER, status);
    try {
      const response = await PipelineAPI.get(status || undefined);
      commit(types.SET_PIPELINE_CONVERSATIONS, {
        conversationsByStage: response.data.conversations_by_stage,
        stages: response.data.stages,
      });
    } catch (error) {
      // Error is expected to be handled by the API layer
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isFetching: false });
    }
  },

  updateStage: async function updateConversationStage(
    { commit },
    { conversationId, stage, fromStage }
  ) {
    commit(types.SET_PIPELINE_UI_FLAG, { isUpdating: true });
    try {
      const response = await PipelineAPI.updateStage(conversationId, stage);
      commit(types.UPDATE_PIPELINE_CONVERSATION, {
        conversation: response.data.conversation,
        fromStage,
        toStage: stage,
      });
      return response.data.conversation;
    } catch (error) {
      const errorMessage = error?.response?.data?.error || error?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_PIPELINE_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_PIPELINE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_PIPELINE_CONVERSATIONS](_state, { conversationsByStage, stages }) {
    _state.conversationsByStage = conversationsByStage;
    _state.stages = stages;
  },

  [types.SET_PIPELINE_STATUS_FILTER](_state, status) {
    _state.statusFilter = status;
  },

  [types.UPDATE_PIPELINE_CONVERSATION](
    _state,
    { conversation, fromStage, toStage }
  ) {
    // Remove from old stage if it exists
    if (fromStage && _state.conversationsByStage[fromStage]) {
      _state.conversationsByStage[fromStage] = _state.conversationsByStage[
        fromStage
      ].filter(c => c.id !== conversation.id);
    }

    // Add to new stage if stage is not null
    if (toStage) {
      if (!_state.conversationsByStage[toStage]) {
        _state.conversationsByStage[toStage] = [];
      }
      // Check if conversation already exists in the stage
      const existingIndex = _state.conversationsByStage[toStage].findIndex(
        c => c.id === conversation.id
      );
      if (existingIndex === -1) {
        _state.conversationsByStage[toStage].unshift(conversation);
      } else {
        // Update existing conversation
        _state.conversationsByStage[toStage][existingIndex] = conversation;
      }
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
