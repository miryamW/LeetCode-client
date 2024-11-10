<template>
  <div>
    <h1>Update Question</h1>
    <form @submit.prevent="updateQuestion">
      <label>Description:</label>
      <input v-model="question.description" required />
      <label>Level:</label>
      <input type="number" v-model="question.level" required />
      <div v-for="(test, index) in question.tests" :key="index">
        <label>Test {{ index + 1 }} Input:</label>
        <input v-model="test.input" required />
        <label>Test {{ index + 1 }} Expected Output:</label>
        <input v-model="test.expected_output" required />
      </div>
      <button type="button" @click="addTest">Add Test</button>
      <button type="submit">Update</button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router';
import { ref, onMounted } from 'vue';

const question = ref({
  id: '',
  description: '',
  level: 1,
  tests: [
    {
      input: '',
      expectedOutput: ''
    }
  ]
});

onMounted(() => {
  const route = useRoute();
  question.value.id = route.query.id as string; 
  fetchQuestion();
});

const fetchQuestion = async () => {
  try {
    const response = await fetch(`http://localhost:8080/questions/${question.value.id}`);
    if (!response.ok) {
      throw new Error('Failed to fetch question');
    }
    const data = await response.json();
    question.value = data;
  } catch (error) {
    console.error('Error fetching question:', error);
    alert('Failed to fetch question');
  }
};

const updateQuestion = async () => {
  try {
    const response = await fetch('http://localhost:8080/questions', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(question.value)
    });
    if (!response.ok) {
      throw new Error('Failed to update question');
    }
    alert('Question updated successfully');
  } catch (error) {
    console.error('Error updating question:', error);
    alert('Failed to update question');
  }
};

const addTest = () => {
  question.value.tests.push({ input: '', expected_output: '' });
};
</script>
