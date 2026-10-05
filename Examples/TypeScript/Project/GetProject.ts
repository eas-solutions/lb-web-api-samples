import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  type GetProjectParameter,
  type GetProjectResponse,
  printApiResult,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      'internal-project-id': { type: 'string' },
      'include-companies-and-persons': { type: 'boolean', default: false },
      'include-custom-definition-values': { type: 'boolean', default: false },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx Project/GetProject.ts --internal-project-id <GUID> [options]

Retrieves details of a single project by its internal GUID.

${commonConfigHelpText}

Script options:
  --internal-project-id <GUID>           Required internal project GUID
  --include-companies-and-persons        Include related company and person records
  --include-custom-definition-values     Include custom field definitions and values
  -h, --help                             Show this help message
`);
    return;
  }

  const internalProjectId = values['internal-project-id'];
  if (!internalProjectId) {
    console.error('Error: --internal-project-id is required.');
    process.exitCode = 1;
    return;
  }

  const client = createClient(extractConfigOverrides(values));

  const parameter: GetProjectParameter = {
    ProjectId: internalProjectId,
    IncludeCompaniesAndPersons: values['include-companies-and-persons'],
    IncludeCustomDefinitionValues: values['include-custom-definition-values'],
  };

  const result = await client.postJson<GetProjectParameter, GetProjectResponse>(
    'Project/GetProject',
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
