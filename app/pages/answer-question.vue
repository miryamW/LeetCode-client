<template>
  <div :class="{'loading': isLoading}">
    <h1>Answer Question</h1>

    <!-- Display Question Details -->
    <div v-if="question">
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

    <!-- Language Tabs -->
    <div class="tabs">
      <button
        :class="{ active: selectedLanguage === 'python' }"
        @click="selectedLanguage = 'python'"
      >
        Python
      </button>
      <button
        :class="{ active: selectedLanguage === 'java' }"
        @click="selectedLanguage = 'java'"
      >
        Java
      </button>
    </div>

    <!-- Answer Form -->
    <form @submit.prevent="runTests">
      <label>Answer:</label>
      <!-- Python Answer Textarea -->
      <textarea
        v-if="selectedLanguage === 'python'"
        v-model="pythonAnswer"
        required
        class="answer-textarea"
      ></textarea>

      <!-- Java Answer Textarea -->
      <textarea
        v-if="selectedLanguage === 'java'"
        v-model="javaAnswer"
        required
        class="answer-textarea"
      ></textarea>

      <button type="submit" :disabled="isLoading">Run Tests</button>
    </form>

    <!-- Test Results (Displayed after running tests) -->
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
          Test {{ result.test_number }} - {{ result.passed ? 'Passed' : 'Failed' }}: {{ result.comments }}
        </li>
      </ul>
    </div>

    <!-- Loading Animation (Spinner) -->
    <div v-if="isLoading" class="spinner">
      <div class="loader"></div>
      <p>Processing...</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';

const pythonAnswer = ref('');
const javaAnswer = ref('');
const results = ref<{ message: any[] }>({ message: [] });
const questionId = ref<string>('');
const question = ref<any>(null);
const selectedLanguage = ref<string>('python');
const isLoading = ref(false); 
onMounted(async () => {
  const route = useRoute();
  questionId.value = route.query.id as string;

  await fetchQuestionDetails(questionId.value);
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
    const response = await fetch('http://localhost:8080/questions/runTests', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: questionId.value,
        solution: selectedLanguage.value === 'python' ? pythonAnswer.value : javaAnswer.value,
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
/* Style for the answer textarea to make it wide and square-like */
.answer-textarea {
  width: 100%;           /* Make it full width */
  height: 400px;         /* Set a fixed height to make it look square */
  border: 1px solid #ccc; /* Light border */
  padding: 10px;         /* Add padding inside the textarea */
  font-size: 16px;       /* Increase font size */
  box-sizing: border-box; /* Ensure padding doesn't affect width */
  resize: none;         /* Disable resizing */
}

/* Style for the tabs */
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

/* Style for the test results container */
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
  width: 300px; /* Set a fixed width for the test result */
}

/* Loading spinner and page dimming */
.loading {
  position: fixed; 
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(255, 255, 255, 0.7); /* Lighten background */
  pointer-events: none; /* Disable interactions with elements behind */
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999; /* Ensure it stays on top of all other elements */
}

.spinner {
  text-align: center;
}

.loader {
  border: 6px solid #f3f3f3; /* Light grey */
  border-top: 6px solid #3498db; /* Blue */
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
