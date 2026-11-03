import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import OpenAI from 'openai';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

const BASE_URL = process.env.RIVER_BASE_URL || 'https://api.river.ai/v1';
const MODEL = process.env.RIVER_DEFAULT_MODEL || 'zai-org/GLM-5.3-Flash';
const API_KEY = process.env.RIVER_API_KEY?.trim();

async function runCliTest() {
  console.log('='.repeat(60));
  console.log('VitalAI - River AI CLI Test Tool');
  console.log('='.repeat(60));
  console.log(`Endpoint : ${BASE_URL}`);
  console.log(`Model    : ${MODEL}`);

  if (!API_KEY || API_KEY === 'your_river_api_key_here') {
    console.error('\n❌ ERROR: RIVER_API_KEY is not configured.');
    console.error('Please configure your API key in river-eval/.env:');
    console.error('  RIVER_API_KEY=your_actual_river_api_key_here\n');
    process.exit(1);
  }

  console.log(`API Key  : [CONFIGURED - ${API_KEY.slice(0, 4)}...${API_KEY.slice(-4)}] (Never logged)`);
  console.log('\nSending test prompt to River AI...');

  const client = new OpenAI({
    baseURL: BASE_URL,
    apiKey: API_KEY,
  });

  const startTime = performance.now();
  try {
    const response = await client.chat.completions.create({
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are VitalAI test evaluator. Provide concise, evidence-based answers.'
        },
        {
          role: 'user',
          content: 'According to 2017 ACC/AHA guidelines, what are the systolic and diastolic cutoffs for normal blood pressure? Answer in 2 short sentences.'
        }
      ],
      temperature: 0.1,
      max_tokens: 200,
    });

    const latencyMs = Math.round(performance.now() - startTime);

    console.log('\n✅ Response Received Successfully!');
    console.log(`Model Used   : ${response.model}`);
    console.log(`Response Time: ${latencyMs} ms`);
    if (response.usage) {
      console.log(`Prompt Tokens: ${response.usage.prompt_tokens}`);
      console.log(`Comp.  Tokens: ${response.usage.completion_tokens}`);
      console.log(`Total  Tokens: ${response.usage.total_tokens}`);
    }
    console.log('-'.repeat(60));
    console.log('Output:');
    console.log(response.choices[0]?.message?.content);
    console.log('-'.repeat(60));
  } catch (err: unknown) {
    const latencyMs = Math.round(performance.now() - startTime);
    console.error(`\n❌ API Call Failed after ${latencyMs} ms:`);
    const errorObj = err as Record<string, unknown>;
    console.error(errorObj?.message || err);
    process.exit(1);
  }
}

runCliTest();
