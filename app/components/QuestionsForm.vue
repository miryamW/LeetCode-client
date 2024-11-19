<script setup lang="ts">
import { defineEmits, defineProps, reactive, watch } from 'vue'
import type { FormError, FormSubmitEvent } from '#ui/types'

const emit = defineEmits(['close', 'updateQuestion'])

const props = defineProps({
  question: {
    type: Object,
    required: false
  }
})

const state = reactive({
  title: '',
  description: '',
  level: 1,
  tests: [
    { Input: '', ExpectedOutput: '' }
  ]
})

watch(() => props.question, (newQuestion) => {
  console.log("OK it is workkk!");
  console.log(newQuestion);
  
  if (newQuestion) {
    state.title = newQuestion.Title
    state.description = newQuestion.Description
    state.level = newQuestion.Level
    state.tests = newQuestion.Tests || [{ Input: '', ExpectedOutput: '' }]
  }
}, { immediate: true })

const validate = (state: any): FormError[] => {
  const errors = []
  if (!state.title) errors.push({ path: 'title', message: 'Please enter a title.' })
  if (!state.description) errors.push({ path: 'description', message: 'Please enter a description.' })
  if (state.level < 1 || state.level > 5) errors.push({ path: 'level', message: 'Level should be between 1 and 5.' })
  if (!state.tests || state.tests.length === 0) errors.push({ path: 'tests', message: 'At least one test is required.' })
  return errors
}

async function onSubmit(event: FormSubmitEvent<any>) {
  console.log(event.data)
  try {
    const url = props.question ? `http://localhost:8080/questions?id=${props.question.ID}` : 'http://localhost:8080/questions'
    const method = props.question ? 'PUT' : 'POST'
    
    const response = await useFetch(url, {
      method: method,
      body: event.data
    })
    
    alert(props.question ? 'Question updated successfully' : 'Question added successfully')
    emit('close')
  } catch (error) {
    console.error('Error saving question:', error)
    alert('Failed to save question')
  }
}
</script>

<template>
  <UForm
    :validate="validate"
    :validate-on="['submit']"
    :state="state"
    class="space-y-4"
    @submit="onSubmit"
  >
    <UFormGroup label="Title" name="title">
      <UInput v-model="state.title" placeholder="Enter question title" autofocus />
    </UFormGroup>

    <UFormGroup label="Description" name="description">
      <UInput v-model="state.description" placeholder="Describe the question" />
    </UFormGroup>

    <UFormGroup label="Level" name="level">
      <UInput v-model="state.level" type="number" min="1" max="5" placeholder="Enter difficulty level" />
    </UFormGroup>

    <UFormGroup label="Tests" name="tests">
      <div v-for="(test, index) in state.tests" :key="index" class="space-y-2">
        <UFormGroup label="Test Input" name="input">
          <UInput v-model="test.Input" placeholder="Enter input for test" />
        </UFormGroup>

        <UFormGroup label="Expected Output" name="expected_output">
          <UInput v-model="test.ExpectedOutput" placeholder="Enter expected output for test" />
        </UFormGroup>
      </div>
      <UButton label="Add Test" color="blue" @click="state.tests.push({ Input: '', ExpectedOutput: '' })" />
    </UFormGroup>

    <div class="flex justify-end gap-3">
      <UButton label="Cancel" color="gray" variant="ghost" @click="emit('close')" />
      <UButton type="submit" label="Save" color="black" />
    </div>
  </UForm>
</template>
