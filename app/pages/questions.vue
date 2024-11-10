<template>
  <div>
    <h1>Questions List</h1>
    <ul>
      <li v-for="question in questions" :key="question.ID">
        <h3>{{ question.Description }}</h3>
        <p>Level: {{ question.Level }}</p>
        
        <div class="buttons">
          <button @click="deleteQuestion(question.ID)">Delete</button>
          <button @click="editQuestion(question.ID)">Edit</button>
          <button @click="answerQuestion(question.ID)">Answer</button>
        </div>

        <ul>
          <li v-for="(test, index) in question.tests" :key="index">
            <strong>Test {{ index + 1 }}:</strong>
            <div><strong>Input:</strong> {{ test.Input }}</div>
            <div><strong>Expected Output:</strong> {{ test.expected_output }}</div>
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

const questions = ref<any[]>([]);

const deleteQuestion = (id: string) => {
  window.location.href = `/delete-question?id=${id}`;
};

const editQuestion = (id: string) => {
  window.location.href = `/update-question?id=${id}`;
};

const answerQuestion = (id: string) => {
  window.location.href = `/answer-question?id=${id}`;
};

const fetchQuestions = async () => {
  try {
    const response = await fetch('http://localhost:8080/questions');
    if (!response.ok) {
      throw new Error('Failed to fetch questions');
    }
    const data = await response.json();
    questions.value = data;
    console.log(questions)
  } catch (error) {
    console.error(error);
  }
};

onMounted(() => {
  fetchQuestions();
});
</script>

<style scoped>
.buttons {
  margin-top: 10px;
}

.buttons button {
  margin-right: 10px;
}
</style>
