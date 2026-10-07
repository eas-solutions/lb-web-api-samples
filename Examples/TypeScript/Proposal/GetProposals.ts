import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  GetProposalsContent,
  type GetProposalsParameter,
  type GetProposalsResponse,
  printApiResult,
  ProposalLoadType,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      'internal-project-id': { type: 'string' },
      take: { type: 'string' },
      skip: { type: 'string' },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx Proposal/GetProposals.ts --internal-project-id <GUID> [options]

Retrieves proposals associated with a specific project.

${commonConfigHelpText}

Script options:
  --internal-project-id <GUID>  Required internal project GUID
  --take <number>               Maximum number of records to return
  --skip <number>               Number of records to skip
  -h, --help                    Show this help message
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

  const querySettings: GetProposalsParameter['QuerySettings'] = {};
  if (values.take !== undefined) {
    querySettings.Take = Number.parseInt(values.take, 10);
  }
  if (values.skip !== undefined) {
    querySettings.Skip = Number.parseInt(values.skip, 10);
  }

  const parameter: GetProposalsParameter = {
    ProjectId: internalProjectId,
    Content: [GetProposalsContent.Proposals],
    LoadOptions: [ProposalLoadType.AllProposals],
    ...(Object.keys(querySettings).length > 0 ? { QuerySettings: querySettings } : {}),
  };

  const result = await client.postJson<GetProposalsParameter, GetProposalsResponse>(
    'Proposal/GetProposals',
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
