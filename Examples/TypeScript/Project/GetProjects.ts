import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  GetProjectsContent,
  type GetProjectsParameter,
  type GetProjectsResponse,
  PredicateCondition,
  PredicateOperator,
  printApiResult,
  type QueryWhere,
} from '../lbapi/index.js';

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      name: { type: 'string' },
      take: { type: 'string' },
      skip: { type: 'string' },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx Project/GetProjects.ts [options]

Retrieves projects accessible to the authenticated user.

${commonConfigHelpText}

Script options:
  --name <string>  Filter projects where Description contains the specified text
  --take <number>  Maximum number of records to return
  --skip <number>  Number of records to skip
  -h, --help       Show this help message
`);
    return;
  }

  const client = createClient(extractConfigOverrides(values));

  const whereFilters: QueryWhere[] = [];
  if (values.name) {
    whereFilters.push({
      Condition: PredicateCondition.And,
      Field: 'Description',
      IgnoreCase: true,
      IsComplex: false,
      Operator: PredicateOperator.Contains,
      Value: {
        StringValue: values.name,
        TypeCode: 18,
        TypeName: 'System.String',
        IsEnum: false,
      },
    });
  }

  const querySettings: GetProjectsParameter['QuerySettings'] = {};
  if (values.take !== undefined) {
    querySettings.Take = Number.parseInt(values.take, 10);
  }
  if (values.skip !== undefined) {
    querySettings.Skip = Number.parseInt(values.skip, 10);
  }
  if (whereFilters.length > 0) {
    querySettings.Where = whereFilters;
  }

  const parameter: GetProjectsParameter = {
    ProjectsContent: [GetProjectsContent.Projects],
    ...(Object.keys(querySettings).length > 0 ? { QuerySettings: querySettings } : {}),
  };

  const result = await client.postJson<GetProjectsParameter, GetProjectsResponse>(
    'Project/GetProjects',
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
