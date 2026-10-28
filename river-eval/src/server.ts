import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import OpenAI from 'openai';
import { PROMPT_PRESETS } from './presets.js';
import { ChatRequest, ChatResponse, HealthStatusResponse } from './types.js';

// Resolve directory paths for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from river-eval/.env or parent .env
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config(); // fallback to cwd

const PORT = parseInt(process.env.PORT || '3001', 10);
const DEFAULT_MODEL = process.env.RIVER_DEFAULT_MODEL || 'zai-org/GLM-5.3-Flash';
const BASE_URL = process.env.RIVER_BASE_URL || 'https://api.river.ai/v1';

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

// Serve frontend static assets
const publicPath = path.resolve(__dirname, '../public');
app.use(express.static(publicPath));

/**
 * Helper to get an OpenAI client configured for River AI.
 * Always created with current process.env.RIVER_API_KEY so changing .env
 * takes effect without restarting if needed.
 */
function getRiverClient(): { client: OpenAI | null; error?: string } {
  const apiKey = process.env.RIVER_API_KEY?.trim();
  if (!apiKey || apiKey === 'your_river_api_key_here') {
    return {
      client: null,
      error: 'RIVER_API_KEY is not set or contains the placeholder value in .env. Please add your actual River AI API key.'
    };
  }

  const client = new OpenAI({
    baseURL: BASE_URL,
    apiKey: apiKey,
  });

  return { client };
}

/**
 * GET /api/health
 * Returns service status without ever exposing the API key string
 */
app.get('/api/health', (_req, res) => {
  const apiKey = process.env.RIVER_API_KEY?.trim();
  const hasValidKeyConfigured = Boolean(apiKey && apiKey !== 'your_river_api_key_here' && apiKey.length > 5);

  const response: HealthStatusResponse = {
    status: hasValidKeyConfigured ? 'ok' : 'configuration_needed',
    hasApiKey: hasValidKeyConfigured,
    defaultModel: DEFAULT_MODEL,
    baseUrl: BASE_URL,
    serverTime: new Date().toISOString(),
    nodeVersion: process.version,
  };

  res.json(response);
});

/**
 * GET /api/presets
 * Returns the 8 pre-configured clinical health test presets
 */
app.get('/api/presets', (_req, res) => {
  res.json({
    presets: PROMPT_PRESETS,
    total: PROMPT_PRESETS.length,
    disclaimer: 'Fictional test data only. For experimental model evaluation, not a medical device or diagnostic system.'
  });
});

/**
 * POST /api/chat
 * Executes a chat completion against River AI's OpenAI-compatible endpoint
 */
app.post('/api/chat', async (req, res) => {
  const startTime = performance.now();
  const body = req.body as ChatRequest;

  if (!body.prompt || typeof body.prompt !== 'string') {
    res.status(400).json({
      success: false,
      error: 'Missing or invalid "prompt" parameter in request body.',
    });
    return;
  }

  const { client, error: keyError } = getRiverClient();
  if (!client) {
    res.status(400).json({
      success: false,
      error: keyError,
      errorDetails: {
        code: 'MISSING_API_KEY',
        troubleshootingHint: 'Open river-eval/.env, set RIVER_API_KEY=your_actual_key, and save the file.',
      },
    });
    return;
  }

  const targetModel = body.model?.trim() || DEFAULT_MODEL;
  const temperature = typeof body.temperature === 'number' ? Math.max(0, Math.min(2, body.temperature)) : 0.2;
  const maxTokens = typeof body.maxTokens === 'number' ? Math.max(1, Math.min(4096, body.maxTokens)) : 2048;
  const responseFormat = body.responseFormat || 'text';

  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [];
  if (body.systemPrompt && body.systemPrompt.trim().length > 0) {
    messages.push({
      role: 'system',
      content: body.systemPrompt.trim(),
    });
  }
  messages.push({
    role: 'user',
    content: body.prompt.trim(),
  });

  const completionParams: OpenAI.Chat.ChatCompletionCreateParamsNonStreaming = {
    model: targetModel,
    messages,
    temperature,
    max_tokens: maxTokens,
  };

  // Only pass response_format if json_object is requested
  if (responseFormat === 'json_object') {
    completionParams.response_format = { type: 'json_object' };
  }

  try {
    const completion = await client.chat.completions.create(completionParams);
    const latencyMs = Math.round(performance.now() - startTime);

    const messageObj = completion.choices[0]?.message as Record<string, unknown> | undefined;
    const content = (messageObj?.content as string) || '';
    const reasoningContent = (messageObj?.reasoning_content as string) || undefined;

    // Attempt to validate JSON if json_object requested or looks like JSON
    let parsedJson: unknown = null;
    let jsonValid = false;

    try {
      // Strip potential leading/trailing markdown fences if the model emitted them
      const cleaned = content.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();
      parsedJson = JSON.parse(cleaned);
      jsonValid = true;
    } catch {
      jsonValid = false;
    }

    const usage = completion.usage ? {
      promptTokens: completion.usage.prompt_tokens,
      completionTokens: completion.usage.completion_tokens,
      totalTokens: completion.usage.total_tokens,
    } : null;

    const responsePayload: ChatResponse = {
      success: true,
      model: completion.model || targetModel,
      content,
      reasoningContent,
      parsedJson: jsonValid ? parsedJson : undefined,
      jsonValid,
      latencyMs,
      usage,
      raw: completion,
    };

    res.json(responsePayload);
  } catch (err: unknown) {
    const latencyMs = Math.round(performance.now() - startTime);
    const errorObj = err as Record<string, unknown>;

    let status = 500;
    let message = 'An unexpected error occurred while communicating with River AI.';
    let troubleshootingHint = 'Check River AI service status and verify your network connectivity.';

    if (errorObj?.status && typeof errorObj.status === 'number') {
      status = errorObj.status;
      if (status === 401) {
        message = 'Authentication failed: Invalid or expired River API key.';
        troubleshootingHint = 'Verify that your RIVER_API_KEY in .env matches the key generated in your River AI account dashboard.';
      } else if (status === 404) {
        message = `Model not found: "${targetModel}".`;
        troubleshootingHint = `Check if the model "${targetModel}" is supported by River AI and available to your API tier.`;
      } else if (status === 429) {
        message = 'Rate limit or quota exceeded on River AI.';
        troubleshootingHint = 'Check your River AI usage limits, credits, or reduce request concurrency.';
      } else if (status >= 500) {
        message = 'River AI remote server error.';
        troubleshootingHint = 'The River AI upstream API returned a 5xx error. Try again shortly.';
      }
    }

    if (errorObj?.message && typeof errorObj.message === 'string') {
      message = errorObj.message;
    }

    res.status(status >= 400 && status < 600 ? status : 500).json({
      success: false,
      model: targetModel,
      content: '',
      latencyMs,
      usage: null,
      error: message,
      errorDetails: {
        status,
        code: (errorObj?.code as string) || 'RIVER_API_ERROR',
        type: (errorObj?.type as string) || 'api_error',
        message,
        troubleshootingHint,
      },
      raw: errorObj,
    });
  }
});

// Fallback route to serve index.html for SPA
app.get('*', (_req, res) => {
  res.sendFile(path.join(publicPath, 'index.html'));
});

// Start listening on all network interfaces (0.0.0.0) so emulators and local devices can connect
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[VitalAI River Eval] Server listening on http://localhost:${PORT} and http://0.0.0.0:${PORT}`);
  console.log(`[VitalAI River Eval] Target Endpoint: ${BASE_URL}`);
  console.log(`[VitalAI River Eval] Target Model: ${DEFAULT_MODEL}`);
  console.log(`[VitalAI River Eval] API Key configured: ${process.env.RIVER_API_KEY ? 'Yes (configured)' : 'No (pending .env setup)'}`);
});
