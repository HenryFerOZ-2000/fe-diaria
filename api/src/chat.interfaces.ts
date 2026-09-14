/**
 * Represents a single message in the chat conversation.
 */
export interface ChatMessage {
  role: "user" | "assistant" | "system";
  content: string;
}

/**
 * Request structure for chat with Groq API.
 */
export interface ChatRequest {
  userText: string;
  conversation?: ChatMessage[];
  /** App tradition: `catolica`, `cristiana`, or denomination-neutral `general`. */
  faithTradition?: string;
}

/**
 * Response structure from chat with Groq API.
 */
export interface ChatResponse {
  messages: string[];
  rawContent: string;
}
