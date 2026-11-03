export type ResponseFormatType = 'text' | 'json_object';

export interface ChatRequest {
  prompt: string;
  systemPrompt?: string;
  model?: string;
  temperature?: number;
  maxTokens?: number;
  responseFormat?: ResponseFormatType;
}

export interface TokenUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
}

export interface ChatResponse {
  success: boolean;
  model: string;
  content: string;
  reasoningContent?: string;
  parsedJson?: unknown;
  jsonValid?: boolean;
  latencyMs: number;
  usage: TokenUsage | null;
  raw?: unknown;
  error?: string;
  errorDetails?: {
    code?: string;
    type?: string;
    status?: number;
    message?: string;
    troubleshootingHint?: string;
  };
}

export interface PromptPreset {
  id: string;
  category: string;
  categoryBadge: string;
  title: string;
  description: string;
  fictionalPatientContext: string;
  systemPrompt: string;
  userPrompt: string;
  defaultTemperature: number;
  defaultMaxTokens: number;
  responseFormat: ResponseFormatType;
  clinicalEvaluationCriteria: string[];
}

export interface HealthStatusResponse {
  status: 'ok' | 'configuration_needed';
  hasApiKey: boolean;
  defaultModel: string;
  baseUrl: string;
  serverTime: string;
  nodeVersion: string;
}
