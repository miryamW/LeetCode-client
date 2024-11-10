<template>
  <div>
    <h1>Add Question</h1>
    <form @submit.prevent="addQuestion">
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
      <button type="submit">Submit</button>
    </form>
  </div>
</template>

<script>
export default {
  data() {
    return {
      question: {
        description: '',
        level: 1,
        tests: [
          {
            input: '',
            expectedOutput: ''
          }
        ]
      }
    };
  },
  methods: {
    addTest() {
      this.question.tests.push({ input: '', expectedOutput: '' });
    },
    async addQuestion() {
      try {
        const response = await useFetch('http://localhost:8080/questions' ,{
          method: 'post',
          body: this.question
        })
        alert('Question added successfully');
      } catch (error) {
        console.error('Error adding question:', error);
        alert('Failed to add question');
      }
    }
  }
};
</script>
