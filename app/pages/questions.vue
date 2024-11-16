<script setup lang="ts">
import type { Question } from '~/types'
import SettingsMembersList from '~/components/QuestionsList.vue'
const editingQuestion = ref<Question | null>(null)  // כדי לאחסן את השאלה המועדת לעריכה

const { data: questions } = await useFetch<Question[]>('http://localhost:8080/questions', { default: () => [] })

const q = ref('')
const isInviteModalOpen = ref(false)
const isEditModalOpen = ref(false)
const filteredQuestions = computed(() => {
  if (!questions.value) return []
  if(q.value==='') return questions
  return questions.value.filter((question) => {
    return (q.value ===''||question.Title && question.Title.search(new RegExp(q.value, 'i')) !== -1) ||
           (question.Description && question.Description.search(new RegExp(q.value, 'i')) !== -1)
  })
})


function handleEditQuestion(question: Question) {
  console.log("bfd");
  console.log(question);
  
  editingQuestion.value = question  // עדכון השאלה המוערכת
  isEditModalOpen.value = true  // פתיחת המודאל
}

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
            placeholder="Search members"
            autofocus
          />
        </template>

        <!-- ~/components/settings/MembersList.vue -->
       <QuestionsList :questions="filteredQuestions.value" @editQuestion="handleEditQuestion" />
      </UCard>
    </UDashboardSection>

    <UDashboardModal
      v-model="isInviteModalOpen"
      title="Add question"
      description="Add new question"
      :ui="{ width: 'sm:max-w-md' }"
    >
      <!-- ~/components/settings/MembersForm.vue -->
      <QuestionsForm @close="isInviteModalOpen = false" />
    </UDashboardModal>
    <UDashboardModal
      v-model="isEditModalOpen"
      title="Edit question"
      description="Edit the question details"
      :ui="{ width: 'sm:max-w-md' }"
    >
      <!-- ~/components/settings/MembersForm.vue -->
      <QuestionsForm :question="editingQuestion" @close="isEditModalOpen = false" />
    </UDashboardModal>
  </UDashboardPanelContent>
</template>
