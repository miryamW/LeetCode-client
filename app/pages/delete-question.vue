<template>
  <div>
    <h1>Delete Question</h1>
    <p>Are you sure you want to delete the question with ID: {{ questionId }}?</p>
    <button @click="deleteQuestion">Delete</button>
  </div>
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router';
import { ref, onMounted } from 'vue';

const questionId = ref<string>('');

onMounted(() => {
  const route = useRoute();
  questionId.value = route.query.id as string; 
});

const deleteQuestion = async () => {
  try {
    const response = await fetch(`http://localhost:8080/questions/${questionId.value}`, {
      method: 'DELETE'
    });
    if (!response.ok) {
      throw new Error('Failed to delete question');
    }
    alert('Question deleted successfully');
  } catch (error) {
    console.error('Error deleting question:', error);
    alert('Failed to delete question');
  }
};
</script>
