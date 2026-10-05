import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  type LoadPersonsParameter,
  type LoadPersonsResponse,
  printApiResult,
  type QuerySettings,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      'internal-company-id': { type: 'string' },
      name: { type: 'string' },
      'only-active': { type: 'boolean' },
      take: { type: 'string' },
      skip: { type: 'string' },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx CompaniesAndPersons/LoadPersons.ts [options]

Retrieves filtered person records.

${commonConfigHelpText}

Script options:
  --internal-company-id <GUID>  Filter persons by internal company GUID
  --name <string>               Filter persons by name
  --only-active                 Include only active persons
  --take <number>               Maximum number of records to return
  --skip <number>               Number of records to skip
  -h, --help                    Show this help message
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

  const parameter: LoadPersonsParameter = {
    ...(values['internal-company-id'] ? { CompanyID: values['internal-company-id'] } : {}),
    ...(values.name ? { Name: values.name } : {}),
    ...(values['only-active'] !== undefined ? { OnlyActive: values['only-active'] } : {}),
    ...(Object.keys(querySettings).length > 0 ? { QuerySettings: querySettings } : {}),
  };

  const result = await client.postJson<LoadPersonsParameter, LoadPersonsResponse>(
    'CompaniesAndPersons/LoadPersons',
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
