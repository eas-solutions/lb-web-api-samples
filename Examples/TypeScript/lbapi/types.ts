/**
 * TypeScript definitions and enums for the LeegooBuilder Web API.
 */

// --- Numeric Enums ---

export enum OperationFailType {
  NoError = 0,
  NotLoggedIn = 10,
  TokenInvalid = 20,
  ExceptionOnServer = 30,
  ManualFail = 40,
  SerializationError = 50,
  ModelInvalid = 60,
  RequiredParameterMissingOrNull = 70,
  TokenExpired = 80,
  ScriptError = 90,
  SqlConnection = 100,
}

export enum SaveDataMode {
  Auto = 0,
  Insert = 10,
  Update = 20,
}

export enum GetProjectsContent {
  All = 0,
  Projects = 10,
  UserSettings = 20,
  CustomDefinitionValues = 30,
  SystemViews = 40,
  BasicColumDefinitions = 45,
  TableData = 50,
  PersonsAndCompanies = 60,
  SysCodes = 70,
  IsFavorite = 80,
}

export enum GetProposalsContent {
  All = 10,
  Proposals = 20,
  UserSettings = 30,
  CustomDefinitionValues = 40,
  SystemViews = 50,
  TableData = 60,
  PersonsAndCompanies = 70,
  Project = 80,
}

export enum ProposalLoadType {
  AllProposals = 10,
  OwnProposal = 20,
  OwnBusifieldProposals = 30,
  OwnSupplierProposals = 40,
  OwnUserGroupProposals = 50,
  OwnUserGroupProposalsWithChilds = 60,
  OwnUserGroupProposalsRegardingOwner = 70,
  OwnUserGroupProposalsWithChildsRegardingOwner = 80,
}

export enum PredicateOperator {
  LessThan = 1,
  LessThanOrEqual = 2,
  Equals = 3,
  NotEquals = 4,
  GreaterThanOrEqual = 5,
  GreaterThan = 6,
  StartsWith = 7,
  EndsWith = 8,
  Contains = 9,
  Undefined = 10,
  Between = 20,
}

export enum PredicateCondition {
  And = 1,
  Or = 2,
}

export enum SortDirection {
  Ascending = 1,
  Descending = 2,
}

// --- Common Contracts ---

export interface OperationResult {
  successful: boolean;
  operationFailType: OperationFailType;
  shortMessage: string | null;
  detailedMessage: string | null;
  translatorTerm?: string | null;
  throwException?: boolean;
  exception?: unknown;
}

export interface SerializableObject {
  StringValue?: string | null;
  TypeCode?: number;
  TypeName?: string | null;
  IsEnum?: boolean;
}

export interface QueryWhere {
  Field?: string;
  Operator?: PredicateOperator;
  Value?: SerializableObject;
  Condition?: PredicateCondition;
  IgnoreCase?: boolean;
  IsComplex?: boolean;
  Predicate?: QueryWhere[];
}

export interface QuerySort {
  PropertyName: string;
  Direction: SortDirection;
}

export interface QuerySearch {
  Fields: string[];
  Key: string;
  IgnoreCase?: boolean;
}

export interface QueryIndex {
  Field: string;
  Value: SerializableObject;
}

export interface QuerySettings {
  Skip?: number;
  Take?: number;
  Sorts?: QuerySort[];
  Where?: QueryWhere[];
  Search?: QuerySearch[];
  QueryIndex?: QueryIndex;
  DistinctBy?: string;
  PropertySelection?: unknown;
  Includes?: unknown[];
}

export interface QueryInfo {
  recordsTotal?: number | null;
  selectedItemAtIndex?: number | null;
  selectedItemAtPage?: number | null;
  RecordsTotal?: number | null;
  SelectedItemAtIndex?: number | null;
  SelectedItemAtPage?: number | null;
}

export interface ApplyQueryResult<T> {
  queryInfo?: QueryInfo | null;
  value?: T;
}

// --- Authentication ---

export interface LoginParameter {
  Username: string;
  UnencryptedPassword?: string;
  Language: string;
  Culture: string;
  LoginMethod?: number;
  EncryptedPasswort?: string;
  TokenExpireTimeInMinutes?: number | null;
}

export interface UserWeb {
  id?: string;
  name?: string;
  password?: string | null;
  token?: string;
  loginCulture?: string;
  loginLanguage?: string;
  claims?: Record<string, string[]>;
}

export interface LoginResponse {
  operationResult: OperationResult;
  renewalToken?: string | null;
  user?: UserWeb | null;
}

// --- Project ---

export interface ProjectItem {
  internalProjectID: string;
  projectID: string;
  description?: string | null;
  [key: string]: unknown;
}

export interface GetProjectsParameter {
  ProjectsContent: GetProjectsContent[];
  QuerySettings?: QuerySettings;
  SchemaName?: string;
  Language?: string;
  LoadOptions?: number[];
  ReplaceCustomOverwriteColumns?: boolean;
  ReplaceSyscodesWithValues?: boolean;
}

export interface GetProjectsResponse {
  operationResult: OperationResult;
  projects?: ProjectItem[];
  queryInfo?: QueryInfo | null;
  customDefinitionValues?: Record<string, unknown> | null;
  [key: string]: unknown;
}

export interface GetProjectParameter {
  ProjectId: string;
  IncludeCompaniesAndPersons?: boolean;
  IncludeCustomDefinitionValues?: boolean;
}

export interface GetProjectResponse {
  operationResult: OperationResult;
  project?: ProjectItem | null;
  customDefinitionValues?: Record<string, SerializableObject> | null;
  [key: string]: unknown;
}

// --- Proposal ---

export interface ProposalItem {
  internalProposalID: string;
  proposalID: string;
  description?: string | null;
  internalProjectID?: string;
  [key: string]: unknown;
}

export interface GetProposalsParameter {
  ProjectId?: string | null;
  Content: GetProposalsContent[];
  LoadOptions: ProposalLoadType[];
  LoadAllProposals?: boolean;
  OnlyFavorites?: boolean;
  QuerySettings?: QuerySettings;
  SelectedView?: string;
  Language?: string;
}

export interface GetProposalsResponse {
  operationResult: OperationResult;
  proposals?: ProposalItem[];
  queryInfo?: QueryInfo | null;
  customDefinitionValues?: Record<string, Record<string, SerializableObject>> | null;
  [key: string]: unknown;
}

export interface GetProposalParameter {
  ProposalId: string;
  IncludeCustomDefinitionValues?: boolean;
  IncludeCompaniesAndPersons?: boolean;
}

export interface GetProposalResponse {
  operationResult: OperationResult;
  proposal?: ProposalItem | null;
  customDefinitionValues?: Record<string, SerializableObject> | null;
  [key: string]: unknown;
}

// --- Companies and Persons ---

export interface CompanyItem {
  internalCompanyID?: string;
  companyID?: string;
  name1?: string;
  name2?: string;
  name3?: string;
  matchCode?: string;
  isInterestedParty?: boolean;
  [key: string]: unknown;
}

export interface PersonItem {
  internalPersonID?: string;
  internalCompanyID?: string;
  personID?: string;
  name?: string;
  firstName?: string;
  fullName?: string;
  isActive?: number | boolean;
  [key: string]: unknown;
}

export interface LoadCompaniesParameter {
  Name?: string;
  CompanyID?: string;
  CompanyIds?: string[];
  Country?: number;
  IncludePersonInfos?: boolean;
  Location?: string;
  MatchCode?: string;
  QuerySettings?: QuerySettings;
  ZipCode?: string;
}

export interface LoadCompaniesResponse {
  operationResult: OperationResult;
  companies?: ApplyQueryResult<CompanyItem[]>;
}

export interface InitCompanyParameter {
  Company?: CompanyItem;
  IsInterestedParty?: boolean;
}

export interface InitCompanyResponse {
  operationResult: OperationResult;
  company?: CompanyItem | null;
}

export interface SaveCompanyParameter {
  Company: CompanyItem;
  SaveDataMode?: SaveDataMode;
}

export interface SaveCompanyResponse {
  operationResult: OperationResult;
  company?: CompanyItem | null;
}

export interface LoadPersonsParameter {
  CompanyID?: string | null;
  FirstName?: string;
  Name?: string;
  PersonIds?: string[];
  QuerySettings?: QuerySettings;
  OnlyActive?: boolean;
}

export interface LoadPersonsResponse {
  operationResult: OperationResult;
  persons?: ApplyQueryResult<PersonItem[]>;
}

export interface InitPersonParameter {
  InternalCompanyID?: string | null;
  Person?: PersonItem | null;
}

export interface InitPersonResponse {
  operationResult: OperationResult;
  person?: PersonItem | null;
}

export interface SavePersonParameter {
  Person: PersonItem;
  SaveDataMode?: SaveDataMode;
}

export interface SavePersonResponse {
  operationResult: OperationResult;
  person?: PersonItem | null;
}
