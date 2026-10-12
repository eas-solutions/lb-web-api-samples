import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  type GetProposalParameter,
  type GetProposalResponse,
  printApiResult,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      'internal-proposal-id': { type: 'string' },
      'include-custom-definition-values': { type: 'boolean', default: false },
      'include-companies-and-persons': { type: 'boolean', default: false },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx Proposal/GetProposal.ts --internal-proposal-id <GUID> [options]

Retrieves details of a single proposal by its internal GUID.

${commonConfigHelpText}

Script options:
  --internal-proposal-id <GUID>       Required internal proposal GUID
  --include-custom-definition-values  Include custom field definitions and values
  --include-companies-and-persons     Include related company and person records
  -h, --help                          Show this help message
`);
    return;
  }

  const internalProposalId = values['internal-proposal-id'];
  if (!internalProposalId) {
    console.error('Error: --internal-proposal-id is required.');
    process.exitCode = 1;
    return;
  }

  const client = createClient(extractConfigOverrides(values));

  const parameter: GetProposalParameter = {
    ProposalId: internalProposalId,
    IncludeCustomDefinitionValues: values['include-custom-definition-values'],
    IncludeCompaniesAndPersons: values['include-companies-and-persons'],
  };

  const result = await client.postJson<GetProposalParameter, GetProposalResponse>(
    'Proposal/GetProposal',
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
