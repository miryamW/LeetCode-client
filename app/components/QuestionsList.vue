<script setup lang="ts">
import { defineProps, PropType, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { Question } from '~/types'

defineProps({
  questions: {
    type: Array as PropType<Question[]> ,
    default: () => []
  },
  isEditModalOpen: {
    type: Boolean,
    default: false
  },
  updateIsEditModalOpen: {
    type: Function as PropType<(value: boolean) => void>,
    required: true
  }
})

const emit = defineEmits<{
  (event: 'update:isEditModalOpen', value: boolean): void;
  (event: 'editQuestion', question: Question): void;  
}>()

const router = useRouter()
const editingQuestion = ref<Question | null>(null)

function getItems(question: Question) {
  return [[{
    label: 'Edit question',
    click: () => {
      editingQuestion.value = question
      emit('update:isEditModalOpen', true)  
      emit('editQuestion', question)  
    }
  }, {
    label: 'Remove question',
    labelClass: 'text-red-500 dark:text-red-400',
    click: () => removeQuestion(question.ID)
  }, {
    label: 'Answer question',
    click: () => router.push({ name: 'answer-question', query: { id: question.ID } })
  }]]
}

async function removeQuestion(questionId: string) {
  try {
    const response = await fetch(`http://localhost:8080/questions/${questionId}`, {
      method: 'DELETE'
    })
    if (!response.ok) {
      throw new Error('Failed to delete question')
    }
    alert('Question deleted successfully')
    router.push({ path: router.currentRoute.value.path })
  } catch (error) {
    console.error('Error deleting question:', error)
    alert('Failed to delete question')
  }
}
</script>


<template>
  <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-800">
    <li
      v-for="(question, index) in questions"
      :key="index"
      class="flex items-center justify-between gap-3 py-3 px-4 sm:px-6"
    >
      <div class="flex items-center gap-3 min-w-0">
        <div class="text-sm min-w-0">
          <p class="text-gray-900 dark:text-white font-medium truncate">
            {{ question.Title }}
          </p>
          <p class="text-gray-500 dark:text-gray-400 truncate">
           <strong>Level:</strong> {{ question.Level }}
          </p>
        </div>
      </div>

      <div class="flex items-center gap-3">
        <UDropdown :items="getItems(question)" position="bottom-end">
          <UButton icon="i-heroicons-ellipsis-vertical" color="gray" variant="ghost" />
        </UDropdown>
      </div>
    </li>
  </ul>
</template>
