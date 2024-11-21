<!-- <template>
  <UDashboardPanelContent class="pb-24">
    <div :class="{'loading': isLoading}">
      <div v-if="question">
        <h1><strong>{{ question.Title }}</strong></h1>
        <h2>{{ question.Description }}</h2>
        <p><strong>Level:</strong> {{ question.Level }}</p>
        <ul>
          <li>
            <strong>Example:</strong>
            <div>Input: {{question.Tests[0].Input}}</div>
            <div>Expected Output: {{question.Tests[0].ExpectedOutput}}</div>
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
            <div><strong>Input:</strong> {{ result.input }}</div>
            <div><strong>Output:</strong> {{ result.output }}</div>
            <div><strong>Expected Output:</strong> {{ result.expectedOutput }}</div>
            <div v-if="result.comments && result.comments!=''">
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
const results = ref<{ message: any[], errors: ErrorLine[] }>({ message: [], errors: [] });
const questionId = ref<string>('');
const question = ref<any>(null);
const selectedLanguage = ref<string>('python');
const isLoading = ref(false);
let editorInstance: monaco.editor.IStandaloneCodeEditor | null = null;

interface ErrorLine {
  line: string;
  message: string;
}
const generateFunctionSignature = (title: string, inputTypes: string, outputType: string, language: string) => {
  const functionName = title.toLowerCase().replace(/ /g, '_');
  
  const inputTypesArray = inputTypes.split(',').map((type, index) => {
    let varName = '';
    switch(type.trim()) {
      case 'int':
        varName = `num${index + 1}`;
        break;
      case 'double':
        varName = `dou${index + 1}`;
        break;
      case 'string':
        varName = `str${index + 1}`;
        break;
      case 'string[]':
        varName = `arr${index + 1}`;
        break;
      case 'matrix':
        varName = `mat${index + 1}`;
        break;
      default:
        varName = `param${index + 1}`;
        break;
    }
    return varName;
  });

  const inputSignature = inputTypesArray.join(', ');

  if (language === 'python') {
    return `def ${functionName}(${inputSignature}):`;
  }

  if (language === 'java') {
    const className = functionName.charAt(0).toUpperCase() + functionName.slice(1); 
    return `public class Main {\n    public static ${outputType} ${className}(${inputSignature}) {\n        // Your code here\n    }\n}`;
  }

  return '';
};



onMounted(async () => {
  const route = useRoute();
  questionId.value = route.query.id as string;

  await fetchQuestionDetails(questionId.value);
  console.log(question.value);
  
  const functionSignaturePython = generateFunctionSignature(
        question.value.Title,
        question.value.InputTypes,
        question.value.OutputType,
        'python'
      );
      
      const functionSignatureJava = generateFunctionSignature(
        question.value.Title,
        question.value.InputTypes,
        question.value.OutputType,
        'java'
      );
  const initialCodePython = `${functionSignaturePython}\n    # Your code here\n`;
  const initialCodeJava = functionSignatureJava;
  const initialCode = selectedLanguage.value === 'python' ? initialCodePython : initialCodeJava;

  editorInstance = monaco.editor.create(document.querySelector('.editor-container') as HTMLElement, {
    value: initialCode,
    language: selectedLanguage.value,
    theme: 'vs-dark',
  });

  watch(selectedLanguage, (newLang) => {
    let newValue = '';
        if (newLang === 'python') {
          newValue = `${functionSignaturePython}\n    # Your code here\n`;
        } else if (newLang === 'java') {
          newValue = functionSignatureJava;
        }
    if (editorInstance) {
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
  results.value.errors = [];

  const solution = editorInstance ? editorInstance.getValue() : '';

  if (selectedLanguage.value === 'python') {
    const functionRegex = /\bdef\b\s+\w+/; 
    if (!functionRegex.test(solution)) {
      alert('Required a function in python');
      isLoading.value = false;
      return;
    }
  } else if (selectedLanguage.value === 'java') {
    const functionRegex = /\bpublic\b\s+(?!class)\w+/; 
    if (!functionRegex.test(solution)) {
      alert('Required a public function in java');
      isLoading.value = false;
      return;
    }
  }

  try {
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

.error-line {
  background-color: rgba(255, 0, 0, 0.3);
  border: 5px solid red; 
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

.error-line {
  background-color: rgba(255, 0, 0, 0.3);
}
</style> -->
<template>
  <UDashboardPanelContent class="pb-24">
    <div :class="{'loading': isLoading}">
      <div v-if="question">
        <h1><strong>{{ question.Title }}</strong></h1>
        <h2>{{ question.Description }}</h2>
        <p><strong>Level:</strong> {{ question.Level }}</p>
        <ul>
          <li>
            <strong>Example:</strong>
            <div>Input: {{question.Tests[0].Input}}</div>
            <div>Expected Output: {{question.Tests[0].ExpectedOutput}}</div>
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
            <div><strong>Input:</strong> {{ result.input }}</div>
            <div><strong>Output:</strong> {{ result.output }}</div>
            <div><strong>Expected Output:</strong> {{ result.expectedOutput }}</div>
            <div v-if="result.comments && result.comments!=''">
              <strong>!</strong> {{ result.comments }}
            </div>
          </li>
        </ul>
      </div>

      <div class="overlay" v-if="isLoading">
        <div class="spinner">
          <div class="loader"></div>
          <p>Processing...</p>
        </div>
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
const results = ref<{ message: any[], errors: ErrorLine[] }>({ message: [], errors: [] });
const questionId = ref<string>('');
const question = ref<any>(null);
const selectedLanguage = ref<string>('python');
const isLoading = ref(false);
let editorInstance: monaco.editor.IStandaloneCodeEditor | null = null;

interface ErrorLine {
  line: string;
  message: string;
}

const generateFunctionSignature = (title: string, inputTypes: string, outputType: string, language: string) => {
  const functionName = title.toLowerCase().replace(/ /g, '_');

  const inputTypesArray = inputTypes.split(',').map((type, index) => {
    let varName = '';
    switch (type.trim()) {
      case 'int':
        varName = `num${index + 1}`;
        break;
      case 'double':
        varName = `dou${index + 1}`;
        break;
      case 'string':
        varName = `str${index + 1}`;
        break;
      case 'string[]':
        varName = `arr${index + 1}`;
        break;
      case 'matrix':
        varName = `mat${index + 1}`;
        break;
      default:
        varName = `param${index + 1}`;
        break;
    }
    return varName;
  });

  const inputSignature = inputTypesArray.join(', ');

  if (language === 'python') {
    return `def ${functionName}(${inputSignature}):`;
  }

  if (language === 'java') {
    const className = functionName.charAt(0).toUpperCase() + functionName.slice(1);
    return `public class Main {\n    public static ${outputType} ${className}(${inputSignature}) {\n        // Your code here\n    }\n}`;
  }

  return '';
};

onMounted(async () => {
  const route = useRoute();
  questionId.value = route.query.id as string;

  await fetchQuestionDetails(questionId.value);

  const functionSignaturePython = generateFunctionSignature(
    question.value.Title,
    question.value.InputTypes,
    question.value.OutputType,
    'python'
  );

  const functionSignatureJava = generateFunctionSignature(
    question.value.Title,
    question.value.InputTypes,
    question.value.OutputType,
    'java'
  );

  const initialCodePython = `${functionSignaturePython}\n    # Your code here\n`;
  const initialCodeJava = functionSignatureJava;
  const initialCode = selectedLanguage.value === 'python' ? initialCodePython : initialCodeJava;

  editorInstance = monaco.editor.create(document.querySelector('.editor-container') as HTMLElement, {
    value: initialCode,
    language: selectedLanguage.value,
    theme: 'vs-dark',
  });

  watch(selectedLanguage, (newLang) => {
    let newValue = '';
    if (newLang === 'python') {
      newValue = `${functionSignaturePython}\n    # Your code here\n`;
    } else if (newLang === 'java') {
      newValue = functionSignatureJava;
    }
    if (editorInstance) {
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
  results.value.errors = [];

  const solution = editorInstance ? editorInstance.getValue() : '';

  if (selectedLanguage.value === 'python') {
    const functionRegex = /\bdef\b\s+\w+/;
    if (!functionRegex.test(solution)) {
      alert('Required a function in python');
      isLoading.value = false;
      return;
    }
  } else if (selectedLanguage.value === 'java') {
    const functionRegex = /\bpublic\b\s+(?!class)\w+/;
    if (!functionRegex.test(solution)) {
      alert('Required a public function in java');
      isLoading.value = false;
      return;
    }
  }

  try {
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

.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(255, 255, 255, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  pointer-events: none;
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
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>