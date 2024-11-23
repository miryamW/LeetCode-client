<script setup lang="ts">
import type { Question } from '~/types'
import QuestionsList from '~/components/QuestionsList.vue'
const editingQuestion = ref<Question | null>(null)  

const { data: questions, refresh} = await useFetch<Question[]>(`http://localhost:8080/questions`, { default: () => [] })
const q = ref('')
const isInviteModalOpen = ref(false)
const isEditModalOpen = ref(false)
const sortType = ref('')

const filteredQuestions = computed(() => {
  let result = questions.value

  if (q.value) {
    result = result.filter((question) => {
      return question.Title.search(new RegExp(q.value, 'i')) !== -1;
    })
  }

  if (sortType.value === 'abc') {
    result = result.slice().sort((a, b) => a.Title.localeCompare(b.Title))
  } else if (sortType.value === 'level') {
    result = result.slice().sort((a, b) => a.Level - b.Level)
  }

  return result
})

function handleRefreshQuestions() {
  refresh()
}
function handleEditQuestion(question: Question) {  
  editingQuestion.value = question  
  isEditModalOpen.value = true  
}

function setSortType(type: string) {
  sortType.value = type
}

watch([isInviteModalOpen, isEditModalOpen], ([inviteOpen, editOpen]) => {
  if (!inviteOpen && !editOpen) {
    refresh()  
  }
})

</script>

<template>
  <UDashboardPanelContent class="pb-24">
    <UDashboardSection
      title="Our questions list"
      description="Contribute and add questions to the database"
      orientation="horizontal"
      :ui="{ container: 'lg:sticky top-2' }"
    >
      <template #links>
        <UButton
          label="Add question"
          color="black"
          @click="isInviteModalOpen = true"
        />
      </template>

      <UCard
        :ui="{ header: { padding: 'p-4 sm:px-6' }, body: { padding: '' } }"
        class="min-w-0"
      >
        <template #header>
          <UInput
            v-model="q"
            icon="i-heroicons-magnifying-glass"
            placeholder="Search questions"
            autofocus
          />
          <div class="flex space-x-2 mt-2">
            <UButton label="Sort by ABC" @click="setSortType('abc')" />
            <UButton label="Sort by Level" @click="setSortType('level')" />
          </div>
        </template>

        <QuestionsList :questions="filteredQuestions" @editQuestion="handleEditQuestion"   @refreshQuestions="handleRefreshQuestions"/>
      </UCard>
    </UDashboardSection>

    <UDashboardModal
      v-model="isInviteModalOpen"
      title="Add question"
      description="Add new question"
      :ui="{ width: 'sm:max-w-md' }"
    >
      <QuestionsForm @close="isInviteModalOpen = false" />
    </UDashboardModal>
    <UDashboardModal
      v-model="isEditModalOpen"
      title="Edit question"
      description="Edit the question details"
      :ui="{ width: 'sm:max-w-md' }"
    >
      <QuestionsForm :question="editingQuestion" @close="isEditModalOpen = false" />
    </UDashboardModal>
  </UDashboardPanelContent>
</template>
