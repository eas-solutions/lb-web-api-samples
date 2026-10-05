import { parseArgs } from 'node:util';
import {
  ApiError,
  commonConfigHelpText,
  commonConfigOptions,
  createClient,
  extractConfigOverrides,
  type InitPersonParameter,
  type InitPersonResponse,
  type LoadPersonsParameter,
  type LoadPersonsResponse,
  printApiResult,
  SaveDataMode,
  type SavePersonParameter,
  type SavePersonResponse,
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
      'internal-company-id': { type: 'string' },
      'internal-person-id': { type: 'string' },
      name: { type: 'string' },
      'first-name': { type: 'string' },
      'person-id': { type: 'string' },
      update: { type: 'boolean', default: false },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`Usage: npx tsx CompaniesAndPersons/SavePerson.ts [options]

Initializes and saves a new person (Insert mode) or updates an existing one (Update mode).

${commonConfigHelpText}

Script options:
  --internal-company-id <GUID>  Internal GUID of the company the person belongs to (required for Insert)
  --name <string>               Person last name (default: "Test Person at <timestamp>")
  --first-name <string>          Person first name
  --person-id <string>          External/display PersonID (default: generated with timestamp)
  --internal-person-id <GUID>   Internal GUID of an existing person to update
  --update                      Use SaveDataMode.Update instead of Insert
  -h, --help                    Show this help message
`);
    return;
  }

  const client = createClient(extractConfigOverrides(values));
  const timestamp = getTimestampSuffix();
  const isUpdate = values.update || Boolean(values['internal-person-id']);

  if (isUpdate) {
    const internalPersonId = values['internal-person-id'];
    if (!internalPersonId) {
      console.error('Error: --internal-person-id is required when updating a person.');
      process.exitCode = 1;
      return;
    }

    const loadResult = await client.postJson<LoadPersonsParameter, LoadPersonsResponse>(
      'CompaniesAndPersons/LoadPersons',
      {
        PersonIds: [internalPersonId],
      },
    );

    const existing = loadResult.persons?.value?.find(
      (p) => p.internalPersonID?.toLowerCase() === internalPersonId.toLowerCase(),
    );

    if (!existing) {
      console.error(`Error: Person with internal ID ${internalPersonId} not found.`);
      process.exitCode = 1;
      return;
    }

    if (values.name) {
      existing.name = values.name;
    }
    if (values['first-name']) {
      existing.firstName = values['first-name'];
    }
    if (values['person-id']) {
      existing.personID = values['person-id'];
    }
    if (values['internal-company-id']) {
      existing.internalCompanyID = values['internal-company-id'];
    }

    const saveParameter: SavePersonParameter = {
      Person: existing,
      SaveDataMode: SaveDataMode.Update,
    };

    const saveResult = await client.postJson<SavePersonParameter, SavePersonResponse>(
      'CompaniesAndPersons/SavePerson',
      saveParameter,
    );

    printApiResult(saveResult);
  } else {
    const internalCompanyId = values['internal-company-id'];
    if (!internalCompanyId) {
      console.error('Error: --internal-company-id is required to create a new person.');
      process.exitCode = 1;
      return;
    }

    // Initialize defaults from the server
    const initResult = await client.postJson<InitPersonParameter, InitPersonResponse>(
      'CompaniesAndPersons/InitPerson',
      {
        InternalCompanyID: internalCompanyId,
      },
    );

    const person = initResult.person ?? {};
    person.name = values.name ?? `Test Person at ${timestamp}`;
    person.personID = values['person-id'] ?? `Test${timestamp}`;
    if (values['first-name']) {
      person.firstName = values['first-name'];
    }
    person.isActive = 1;
    person.internalCompanyID = internalCompanyId;

    const saveParameter: SavePersonParameter = {
      Person: person,
      SaveDataMode: SaveDataMode.Insert,
    };

    const saveResult = await client.postJson<SavePersonParameter, SavePersonResponse>(
      'CompaniesAndPersons/SavePerson',
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
