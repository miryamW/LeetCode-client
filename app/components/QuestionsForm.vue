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

const validateTitle = (title: string): string | null => {
  const regex = /^[A-Za-z ]+$/; 
  if (!regex.test(title)) {
    return 'Title must contain only English letters and spaces.';
  }
  return null;
}

const validateTypeFormat = (typeStr: string, dataStr: string): string | null => {
  // Helper function to split a string by commas outside brackets
  const splitOutsideBrackets = (str: string): string[] => {
    const result: string[] = [];
    let current = '';
    let bracketLevel = 0;

    for (let i = 0; i < str.length; i++) {
      const char = str[i];

      if (char === ',' && bracketLevel === 0) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
        if (char === '[') bracketLevel++;
        else if (char === ']') bracketLevel--;
      }
    }
    result.push(current.trim()); // Push the last part
    return result;
  };

  // Helper function to check if a value matches a specific type (int, double, string, etc.)
  const isValidType = (value: any, type: string): boolean => {
    if (type === 'int') {
      return Number.isInteger(value);
    } else if (type === 'double') {
      return !isNaN(value) && value % 1 !== 0; // It's a floating point number
    } else if (type === 'string') {
      return typeof value === 'string';
    } else if (type === 'boolean') {
      return value === 'true' || value === 'false'; // Check if value is "true" or "false"
    }
    return false; // Unsupported type
  };

  // Ensure correct JSON formatting for arrays and matrices
  const fixMatrixFormat = (data: string): string => {
    // This will add a comma between the matrix rows if missing
    return data.replace(/(\]\[)/g, '],[');
  };

  const types = typeStr.split(',').map(s => s.trim());
  let data = splitOutsideBrackets(dataStr);

  // Process each type and its corresponding data
  for (let i = 0; i < types.length; i++) {
    const type = types[i];
    let datum = data[i];

    // For matrix types, fix the format if needed
    if (type.endsWith('[][]')) {
      datum = fixMatrixFormat(datum); // Fix the matrix format
    }

    if (type.endsWith('[]')) {
      const itemType = type.slice(0, -2); // Extract the type without the '[]'
      try {
        const arrayData = JSON.parse(datum); // Try parsing as JSON
        if (!Array.isArray(arrayData)) {
          return `Expected array for type ${type} but got ${datum}`;
        }
   
      } catch (e) {
        return `Expected array format for type ${type} but got ${datum}`;
      }
    } else if (type.endsWith('[][]')) {
      const itemType = type.slice(0, -4); // Extract the type without the '[][]'
      try {
        const matrixData = JSON.parse(datum); // Try parsing as JSON
        if (!Array.isArray(matrixData)) {
          return `Expected matrix format for type ${type} but got ${datum}`;
        }
        // Validate each row in the matrix
        for (let row of matrixData) {
          if (!Array.isArray(row)) {
            return `Each row in the matrix should be an array, but got ${JSON.stringify(row)}`;
          }
          // Validate each item in the row
          for (let item of row) {
            if (!isValidType(item, itemType)) {
              return `Invalid item in matrix for type ${type}`;
            }
          }
        }
      } catch (e) {
        return `Expected matrix format for type ${type} but got ${datum}`;
      }
    } else {
      // Validate primitive types
      if (type === 'int') {
        if (!/^-?\d+$/.test(datum)) return `Expected integer for type ${type} but got ${datum}`;
      } else if (type === 'double') {
        if (!/^-?\d+(\.\d+)?$/.test(datum)) return `Expected double for type ${type} but got ${datum}`;
      } else if (type === 'string') {
        if (!/^".*"$/.test(datum)) return `Expected string for type ${type} but got ${datum}. String must be enclosed in double quotes.`;
      }
        else if (type === 'boolean') {
          if (datum !== 'true' && datum !== 'false') return `Expected boolean for type ${type} but got ${datum}`;
        }else {
        return `Unsupported input type: ${type}`;
      }
    }
  }
  return null; // Return null if no errors
};




const validate = (state: any): FormError[] => {
  const errors: FormError[] = []
  const titleError = validateTitle(state.title)
  if (titleError) errors.push({ path: 'title', message: titleError })
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
    emit('updateQuestion')  // emit event to notify about the update
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
      <UInput v-model="state.level" type="number" min="1" max="5" placeholder="Enter difficulty level from 1 to 5" />
    </UFormGroup>

    <UFormGroup label="Input Types" name="inputTypes">
      <UInput v-model="state.inputTypes" placeholder="Enter types of inputs (e.g., int, string, double, boolean, int[], int[][])" />
    </UFormGroup>

    <UFormGroup label="Output Type" name="outputType">
      <UInput v-model="state.outputType" placeholder="Enter type of output (e.g., int)" />
    </UFormGroup>

    <UFormGroup label="Tests" name="tests">
      <div v-for="(test, index) in state.tests" :key="index" class="space-y-2">
        <UFormGroup label="Test Input" :name="`tests[${index}].Input`">
          <UInput v-model="test.Input" placeholder='Enter input for tests (e.g. 1, "aaa", false, 1.2, [2, 3], [[1, 2], [3, 4]])' />
        </UFormGroup>

        <UFormGroup label="Expected Output" :name="`tests[${index}].ExpectedOutput`">
          <UInput v-model="test.ExpectedOutput" placeholder="Enter expected output for test (e.g. 5)" />
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
