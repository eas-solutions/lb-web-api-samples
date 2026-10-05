import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  type LoadCompaniesParameter,
  type LoadCompaniesResponse,
  printApiResult,
  type QuerySettings,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      name: { type: 'string' },
      'company-id': { type: 'string' },
      take: { type: 'string' },
      skip: { type: 'string' },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx CompaniesAndPersons/LoadCompanies.ts [options]

Retrieves filtered company records.

${commonConfigHelpText}

Script options:
  --name <string>        Filter companies by name
  --company-id <string>  Filter companies by company identifier
  --take <number>        Maximum number of records to return
  --skip <number>        Number of records to skip
  -h, --help             Show this help message
`);
    return;
  }

  const client = createClient(extractConfigOverrides(values));

  const querySettings: QuerySettings = {};
  if (values.take !== undefined) {
    querySettings.Take = Number.parseInt(values.take, 10);
  }
  if (values.skip !== undefined) {
    querySettings.Skip = Number.parseInt(values.skip, 10);
  }

  const parameter: LoadCompaniesParameter = {
    ...(values.name ? { Name: values.name } : {}),
    ...(values['company-id'] ? { CompanyID: values['company-id'] } : {}),
    ...(Object.keys(querySettings).length > 0 ? { QuerySettings: querySettings } : {}),
  };

  const result = await client.postJson<LoadCompaniesParameter, LoadCompaniesResponse>(
    'CompaniesAndPersons/LoadCompanies',
    parameter,
  );

  printApiResult(result);
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
