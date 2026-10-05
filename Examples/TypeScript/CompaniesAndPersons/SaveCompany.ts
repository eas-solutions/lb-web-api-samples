import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  type InitCompanyParameter,
  type InitCompanyResponse,
  type LoadCompaniesParameter,
  type LoadCompaniesResponse,
  printApiResult,
  SaveDataMode,
  type SaveCompanyParameter,
  type SaveCompanyResponse,
} from '../lbapi/index.js';

function getTimestampSuffix(): string {
  const now = new Date();
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${pad(now.getDate())}${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      ...commonConfigOptions,
      name: { type: 'string' },
      'company-id': { type: 'string' },
      'internal-company-id': { type: 'string' },
      update: { type: 'boolean', default: false },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx CompaniesAndPersons/SaveCompany.ts [options]

Initializes and saves a new company (Insert mode) or updates an existing one (Update mode).

${commonConfigHelpText}

Script options:
  --name <string>                 Company name (default: "Test Company")
  --company-id <string>           External/display CompanyID (default: generated with timestamp)
  --internal-company-id <GUID>    Internal GUID of an existing company to update
  --update                        Use SaveDataMode.Update instead of Insert
  -h, --help                      Show this help message
`);
    return;
  }

  const client = createClient(extractConfigOverrides(values));
  const timestamp = getTimestampSuffix();
  const companyName = values.name ?? 'Test Company';
  const companyId = values['company-id'] ?? `TestCompany${timestamp}`;

  const isUpdate = values.update || Boolean(values['internal-company-id']);

  if (isUpdate) {
    const internalCompanyId = values['internal-company-id'];
    if (!internalCompanyId) {
      console.error('Error: --internal-company-id is required when updating a company.');
      process.exitCode = 1;
      return;
    }

    // Load existing company to preserve its properties
    const loadResult = await client.postJson<LoadCompaniesParameter, LoadCompaniesResponse>(
      'CompaniesAndPersons/LoadCompanies',
      {
        CompanyIds: [internalCompanyId],
      },
    );

    const existing = loadResult.companies?.value?.find(
      (c) => c.internalCompanyID?.toLowerCase() === internalCompanyId.toLowerCase(),
    );

    if (!existing) {
      console.error(`Error: Company with internal ID ${internalCompanyId} not found.`);
      process.exitCode = 1;
      return;
    }

    if (values.name) {
      existing.name1 = values.name;
    }
    if (values['company-id']) {
      existing.companyID = values['company-id'];
    }

    const saveParameter: SaveCompanyParameter = {
      Company: existing,
      SaveDataMode: SaveDataMode.Update,
    };

    const saveResult = await client.postJson<SaveCompanyParameter, SaveCompanyResponse>(
      'CompaniesAndPersons/SaveCompany',
      saveParameter,
    );

    printApiResult(saveResult);
  } else {
    // Insert mode: initialize defaults first
    const initResult = await client.postJson<InitCompanyParameter, InitCompanyResponse>(
      'CompaniesAndPersons/InitCompany',
      {},
    );

    const company = initResult.company ?? {};
    company.name1 = companyName;
    company.companyID = companyId;

    const saveParameter: SaveCompanyParameter = {
      Company: company,
      SaveDataMode: SaveDataMode.Insert,
    };

    const saveResult = await client.postJson<SaveCompanyParameter, SaveCompanyResponse>(
      'CompaniesAndPersons/SaveCompany',
      saveParameter,
    );

    printApiResult(saveResult);
  }
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
