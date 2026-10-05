import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  extractConfigOverrides,
  maskToken,
  printApiResult,
  TokenManager,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      'show-token': { type: 'boolean', default: false },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx Authentication/Login.ts [options]

Authenticates against the LeegooBuilder Web API and displays the user profile.

${commonConfigHelpText}

Script options:
  --show-token          Display the unmasked bearer token (masked by default)
  -h, --help            Show this help message
`);
    return;
  }

  const tokenManager = new TokenManager(extractConfigOverrides(values));
  const loginResult = await tokenManager.login();

  // Mask token for display unless explicitly requested
  const output = { ...loginResult };
  if (output.user && !values['show-token']) {
    output.user = {
      ...output.user,
      token: maskToken(output.user.token),
    };
  }

  printApiResult(output);
}

main().catch((err: unknown) => {
  process.exitCode = 1;
  if (err instanceof ApiError) {
    console.error(`API Error: ${err.message}`);
    if (err.responseBody) {
      printApiResult(err.responseBody, true);
    }
  } else {
    console.error(`Unexpected error: ${(err as Error).message}`);
  }
});
