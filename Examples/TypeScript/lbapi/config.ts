import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Configuration for the LeegooBuilder Web API client.
 */
export interface LbConfig {
  apiUrl: string;
  username: string;
  password: string;
  language: string;
  culture: string;
}

export interface ConfigOverrides extends Partial<LbConfig> {
  configFile?: string;
}

interface RawConfigFile {
  apiUrl?: string;
  ApiUrl?: string;
  username?: string;
  Username?: string;
  password?: string;
  Password?: string;
  language?: string;
  Language?: string;
  culture?: string;
  Culture?: string;
}

/**
 * Helper to inspect process.argv for a CLI flag (e.g. --username foo or --username=foo).
 */
function getArgvOption(flag: string): string | undefined {
  const index = process.argv.indexOf(flag);
  if (index !== -1 && index + 1 < process.argv.length && !process.argv[index + 1].startsWith('-')) {
    return process.argv[index + 1];
  }
  const prefix = `${flag}=`;
  const match = process.argv.find((arg) => arg.startsWith(prefix));
  if (match) {
    return match.slice(prefix.length);
  }
  return undefined;
}

/**
 * Loads .env file into process.env if present using Node's native process.loadEnvFile.
 */
function tryLoadEnvFiles(): void {
  if (typeof process.loadEnvFile !== 'function') return;

  const currentModuleDir = path.dirname(fileURLToPath(import.meta.url));
  const packageDir = path.resolve(currentModuleDir, '..');

  const envCandidates = [
    path.resolve(process.cwd(), '.env'),
    path.resolve(packageDir, '.env'),
  ];

  for (const envFile of envCandidates) {
    if (fs.existsSync(envFile)) {
      try {
        process.loadEnvFile(envFile);
      } catch {
        // ignore load errors if already partially loaded or unreadable
      }
    }
  }
}

/**
 * Resolves the configuration file path (either explicit or from default locations).
 */
function findConfigFile(explicitPath?: string): string | null {
  if (explicitPath) {
    const resolved = path.resolve(explicitPath);
    if (fs.existsSync(resolved)) {
      return resolved;
    }
    throw new Error(`Specified config file not found: ${explicitPath}`);
  }

  const envConfig = process.env.LB_CONFIG_FILE || getArgvOption('--config');
  if (envConfig) {
    const resolved = path.resolve(envConfig);
    if (fs.existsSync(resolved)) {
      return resolved;
    }
    throw new Error(`Config file specified by LB_CONFIG_FILE / --config not found: ${envConfig}`);
  }

  const currentModuleDir = path.dirname(fileURLToPath(import.meta.url));
  const packageDir = path.resolve(currentModuleDir, '..');

  const candidates = [
    path.resolve(process.cwd(), 'lb-config.local.json'),
    path.resolve(packageDir, 'lb-config.local.json'),
    path.resolve(process.cwd(), 'lb-config.json'),
    path.resolve(packageDir, 'lb-config.json'),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return null;
}

/**
 * Reads and parses a JSON config file.
 */
function loadConfigFile(filePath: string): Partial<LbConfig> {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const parsed = JSON.parse(content) as RawConfigFile;
    return {
      apiUrl: parsed.apiUrl ?? parsed.ApiUrl,
      username: parsed.username ?? parsed.Username,
      password: parsed.password ?? parsed.Password,
      language: parsed.language ?? parsed.Language,
      culture: parsed.culture ?? parsed.Culture,
    };
  } catch (err) {
    throw new Error(`Failed to read/parse config file at ${filePath}: ${(err as Error).message}`);
  }
}

/**
 * Resolves configuration using the following precedence (highest to lowest):
 * 1. Explicit programmatic overrides
 * 2. Command-line flags (--api-url, --username, --password, --language, --culture)
 * 3. Environment variables (LB_API_URL, LB_USERNAME, LB_PASSWORD, LB_LANGUAGE, LB_CULTURE)
 * 4. Config file (lb-config.local.json, lb-config.json, or file specified via --config / LB_CONFIG_FILE)
 * 5. Default fallbacks (http://localhost:56540/api, Administrator, admin, en-GB, en-GB)
 */
export function getConfig(overrides?: ConfigOverrides): LbConfig {
  tryLoadEnvFiles();

  const explicitConfigFile = overrides?.configFile ?? getArgvOption('--config');
  const configFilePath = findConfigFile(explicitConfigFile);
  const fileConfig = configFilePath ? loadConfigFile(configFilePath) : {};

  const cliApiUrl = getArgvOption('--api-url');
  const cliUsername = getArgvOption('--username');
  const cliPassword = getArgvOption('--password');
  const cliLanguage = getArgvOption('--language');
  const cliCulture = getArgvOption('--culture');

  const apiUrl =
    overrides?.apiUrl ??
    cliApiUrl ??
    process.env.LB_API_URL ??
    fileConfig.apiUrl ??
    'http://localhost:56540/api';

  const username =
    overrides?.username ??
    cliUsername ??
    process.env.LB_USERNAME ??
    fileConfig.username ??
    'Administrator';

  const password =
    overrides?.password ??
    cliPassword ??
    process.env.LB_PASSWORD ??
    fileConfig.password ??
    'admin';

  const language =
    overrides?.language ??
    cliLanguage ??
    process.env.LB_LANGUAGE ??
    fileConfig.language ??
    'en-GB';

  const culture =
    overrides?.culture ??
    cliCulture ??
    process.env.LB_CULTURE ??
    fileConfig.culture ??
    'en-GB';

  return {
    apiUrl: apiUrl.replace(/\/+$/, ''),
    username,
    password,
    language,
    culture,
  };
}
