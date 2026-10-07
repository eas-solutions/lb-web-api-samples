import { parseArgs } from 'node:util';
import type { ConfigOverrides } from './config.js';

export const commonConfigOptions = {
  config: { type: 'string' },
  'api-url': { type: 'string' },
  username: { type: 'string' },
  password: { type: 'string' },
  language: { type: 'string' },
  culture: { type: 'string' },
} as const;

export function extractConfigOverrides(values: Record<string, unknown>): ConfigOverrides {
  const overrides: ConfigOverrides = {};
  if (typeof values.config === 'string') overrides.configFile = values.config;
  if (typeof values['api-url'] === 'string') overrides.apiUrl = values['api-url'];
  if (typeof values.username === 'string') overrides.username = values.username;
  if (typeof values.password === 'string') overrides.password = values.password;
  if (typeof values.language === 'string') overrides.language = values.language;
  if (typeof values.culture === 'string') overrides.culture = values.culture;
  return overrides;
}

export const commonConfigHelpText = `Connection & authentication options:
  --config <path>       Path to JSON config file (default: lb-config.local.json or lb-config.json)
  --api-url <url>       API base URL (default: http://localhost:56540/api or LB_API_URL)
  --username <string>   Username for login (default: Administrator or LB_USERNAME)
  --password <string>   Password for login (default: admin or LB_PASSWORD)
  --language <string>   Language code (default: en-GB or LB_LANGUAGE)
  --culture <string>    Culture code (default: en-GB or LB_CULTURE)`;

export { parseArgs };
