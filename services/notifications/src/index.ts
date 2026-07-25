/**
 * @skalway/notifications — stub
 * Extrair de apps/phrx/backend/src/infrastructure/notifications
 */
export const service = {
  name: "notifications",
  version: "0.1.0",
  channels: ["email", "sms", "whatsapp", "in-app"] as const,
};

console.log(`[${service.name}] stub ready — extract from phrx/api notifications`);
