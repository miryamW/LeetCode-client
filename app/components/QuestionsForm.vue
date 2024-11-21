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
  inputTypes: '',
  outputType: '',
  tests: [
    { Input: '', ExpectedOutput: '' }
  ]
})

watch(() => props.question, (newQuestion) => {  
  if (newQuestion) {
    state.title = newQuestion.Title
    state.description = newQuestion.Description
    state.level = newQuestion.Level
    state.inputTypes = newQuestion.InputTypes || ''
    state.outputType = newQuestion.OutputType || ''
    state.tests = newQuestion.Tests || [{ Input: '', ExpectedOutput: '' }]
  }
}, { immediate: true })

const validateTypeFormat = (typeStr: string, dataStr: string): string | null => {
  const types = typeStr.split(',')
  const data = dataStr.split(',')
  if (types.length !== data.length) return `Mismatch between types and data length`
  
  for (let i = 0; i < types.length; i++) {
    const type = types[i].trim()
    const datum = data[i].trim()

    if (type.endsWith('[]')) {
      const itemType = type.slice(0, -2)
      if (!/^(\[.*\])$/.test(datum)) return `Expected array format for type ${type} but got ${datum}`
      const arrayData = JSON.parse(datum)
      if (!Array.isArray(arrayData) || arrayData.some(item => typeof item !== itemType)) return `Invalid array format for type ${type}`
    } else if (type.endsWith('[][]')) {
      const itemType = type.slice(0, -4)
      if (!/^(\[\[.*\]\])$/.test(datum)) return `Expected matrix format for type ${type} but got ${datum}`
      const matrixData = JSON.parse(datum)
      if (!Array.isArray(matrixData) || matrixData.some(row => !Array.isArray(row) || row.some(item => typeof item !== itemType))) return `Invalid matrix format for type ${type}`
    } else {
      if (type === 'int') {
        if (!/^-?\d+$/.test(datum)) return `Expected integer for type ${type} but got ${datum}`
      } else if (type === 'double') {
        if (!/^-?\d+(\.\d+)?$/.test(datum)) return `Expected double for type ${type} but got ${datum}`
      } else if (type === 'string') {
        if (typeof datum !== 'string') return `Expected string for type ${type} but got ${datum}`
      } else {
        return `Unsupported input type: ${type}`
      }
    }
  }
  return null
}

const validate = (state: any): FormError[] => {
  const errors: FormError[] = []
  if (!state.title) errors.push({ path: 'title', message: 'Please enter a title.' })
  if (!state.description) errors.push({ path: 'description', message: 'Please enter a description.' })
  if (state.level < 1 || state.level > 5) errors.push({ path: 'level', message: 'Level should be between 1 and 5.' })
  if (!state.inputTypes) errors.push({ path: 'inputTypes', message: 'Please enter input types.' })
  else {
    state.tests.forEach((test: any, index: number) => {
      const inputError = validateTypeFormat(state.inputTypes, test.Input)
      if (inputError && inputError.startsWith('Unsupported input type:')) errors.push({ path: 'inputTypes', message: inputError })
      else if (inputError) errors.push({ path: `tests[${index}].Input`, message: inputError })
    })
  }
  if (!state.outputType) errors.push({ path: 'outputType', message: 'Please enter output type.' })
  else {
    state.tests.forEach((test: any, index: number) => {
      const outputError = validateTypeFormat(state.outputType, test.ExpectedOutput)
      if (outputError && outputError.startsWith('Unsupported input type:')) errors.push({ path: 'outputType', message: outputError })
      else if (outputError) errors.push({ path: `tests[${index}].ExpectedOutput`, message: outputError })
    })
  }
  if (!state.tests || state.tests.length === 0 || state.tests[0].Input == "" || state.tests[0].ExpectedOutput == "") errors.push({ path: 'tests', message: 'At least one test is required.' })

  return errors
}

async function onSubmit(event: FormSubmitEvent<any>) {
  try {
    const url = props.question ? `http://localhost:8080/questions?id=${props.question.ID}` : 'http://localhost:8080/questions'
    const method = props.question ? 'PUT' : 'POST'
    
    const response = await useFetch(url, {
      method: method,
      body: {
        ...event.data,
        Title: state.title,
        Description: state.description,
        Level: state.level,
        InputTypes: state.inputTypes,
        OutputType: state.outputType,
        Tests: state.tests
      }
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

    <UFormGroup label="Input Types" name="inputTypes">
      <UInput v-model="state.inputTypes" placeholder="Enter types of inputs (e.g., int,string,double)" />
    </UFormGroup>

    <UFormGroup label="Output Type" name="outputType">
      <UInput v-model="state.outputType" placeholder="Enter type of output (e.g., int)" />
    </UFormGroup>

    <UFormGroup label="Tests" name="tests">
      <div v-for="(test, index) in state.tests" :key="index" class="space-y-2">
        <UFormGroup label="Test Input" :name="`tests[${index}].Input`">
          <UInput v-model="test.Input" placeholder="Enter input for test" />
        </UFormGroup>

        <UFormGroup label="Expected Output" :name="`tests[${index}].ExpectedOutput`">
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
