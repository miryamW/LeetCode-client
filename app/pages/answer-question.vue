<template>
  <UDashboardPanelContent class="pb-24">
    <div :class="{'loading': isLoading}">
      <div v-if="question">
        <h1><strong>{{ question.Title }}</strong></h1>
        <h2>{{ question.Description }}</h2>
        <p><strong>Level:</strong> {{ question.Level }}</p>
        <ul>
          <li v-for="(test, index) in question.tests" :key="index">
            <strong>Test {{ index + 1 }}:</strong>
            <div><strong>Input:</strong> {{ test.Input }}</div>
            <div><strong>Expected Output:</strong> {{ test.expected_output }}</div>
          </li>
        </ul>
      </div>

      <div class="tabs">
        <UButton
          label="Python"
          color="black"
          :class="{ active: selectedLanguage === 'python' }"
          @click="selectedLanguage = 'python'"
        />         
        <UButton
          label="Java"
          color="black"
          :class="{ active: selectedLanguage === 'java' }"
          @click="selectedLanguage = 'java'"
        />
      </div>

      <form @submit.prevent="runTests">
        <label>Answer:</label>
        <div ref="editor" class="editor-container"></div>

        <UButton type="submit" :disabled="isLoading">Run Tests</UButton>
      </form>

      <div v-if="results.message.length > 0" class="test-results">
        <h2>Test Results:</h2>
        <ul>
          <li
            v-for="(result, index) in results.message"
            :key="index"
            :style="{
              backgroundColor: result.passed ? 'green' : 'red',
              color: 'white',
              padding: '10px',
              marginBottom: '5px',
              borderRadius: '5px',
            }"
          >
            Test {{ result.test_number }} - {{ result.passed ? 'Passed' : 'Failed' }}: 
            <div><strong>Input:</strong> {{ result.Input }}</div>
            <div><strong>Output:</strong> {{ result.output }}</div>
            <div><strong>Expected Output:</strong> {{ result.ExpectedOutput }}</div>
            <div v-if="result.comments && result.comments.startsWith('compilation error')">
              <strong>!</strong> {{ result.comments }}
            </div>
          </li>
        </ul>
      </div>

      <div v-if="isLoading" class="spinner">
        <div class="loader"></div>
        <p>Processing...</p>
      </div>
    </div>
  </UDashboardPanelContent>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import * as monaco from 'monaco-editor';
import { useRoute } from 'vue-router';

const pythonAnswer = ref('');
const javaAnswer = ref('');
const results = ref<{ message: any[] }>({ message: [] });
const questionId = ref<string>('');
const question = ref<any>(null);
const selectedLanguage = ref<string>('python');
const isLoading = ref(false);
let editorInstance: monaco.editor.IStandaloneCodeEditor | null = null;

onMounted(async () => {
  const route = useRoute();
  questionId.value = route.query.id as string;

  await fetchQuestionDetails(questionId.value);

  editorInstance = monaco.editor.create(document.querySelector('.editor-container') as HTMLElement, {
    value: '',
    language: selectedLanguage.value,
    theme: 'vs-dark',
  });

  watch(selectedLanguage, (newLang) => {
    if (editorInstance) {
      const newValue = newLang === 'java' ? 'public class Main {\n\n}' : '';
      editorInstance.setValue(newValue);
      monaco.editor.setModelLanguage(editorInstance.getModel()!, newLang);
    }
  });
});

const fetchQuestionDetails = async (id: string) => {
  try {
    const response = await fetch(`http://localhost:8080/questions/${id}`);
    if (!response.ok) {
      throw new Error('Failed to fetch question details');
    }
    const data = await response.json();
    question.value = data;
  } catch (error) {
    console.error('Error fetching question details:', error);
    alert('Failed to fetch question details');
  }
};

const runTests = async () => {
  isLoading.value = true;

  results.value.message = [];

  try {
    const solution = editorInstance ? editorInstance.getValue() : '';
    const response = await fetch('http://localhost:8080/questions/runTests', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: questionId.value,
        solution,
        language: selectedLanguage.value
      })
    });
    const data = await response.json();
    results.value = data;
  } catch (error) {
    console.error('Error running tests:', error);
    alert('Failed to run tests');
  } finally {
    isLoading.value = false;
  }
};
</script>

<style scoped>
.editor-container {
  width: 100%;
  height: 400px;
  border: 1px solid #ccc;
  box-sizing: border-box;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
}

.tabs button {
  padding: 10px 20px;
  margin-right: 5px;
  border: 1px solid #ccc;
  cursor: pointer;
  background-color: #f4f4f4;
}

.tabs button.active {
  background-color: #007bff;
  color: white;
  border-color: #007bff;
}

.test-results {
  margin-top: 20px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.test-results ul {
  padding: 0;
  list-style-type: none;
}

.test-results li {
  width: 300px;
}

.loading {
  position: fixed; 
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(255, 255, 255, 0.7);
  pointer-events: none;
  z-index: 9999;
}

.spinner {
  text-align: center;
}

.loader {
  border: 6px solid #f3f3f3;
  border-top: 6px solid #3498db;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
