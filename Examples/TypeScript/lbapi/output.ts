/**
 * JSON formatting and console output utilities.
 *
 * Formats API result JSON with compact single-line rendering for large arrays (> 5 elements),
 * matching the output style of the PowerShell Write-LbApiResult helper.
 */

/**
 * Formats an object or array into pretty JSON.
 * Arrays with more than 5 elements are rendered with each element compressed on a single line.
 */
export function formatApiResult(value: unknown, indent = ''): string {
  if (value === null || value === undefined) {
    return 'null';
  }
  if (typeof value === 'string') {
    return JSON.stringify(value);
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  if (Array.isArray(value)) {
    if (value.length === 0) return '[]';
    const childIndent = indent + '  ';
    if (value.length > 5) {
      const lines = value.map((item) => `${childIndent}${JSON.stringify(item)}`);
      return `[\n${lines.join(',\n')}\n${indent}]`;
    }
    const lines = value.map((item) => `${childIndent}${formatApiResult(item, childIndent)}`);
    return `[\n${lines.join(',\n')}\n${indent}]`;
  }
  if (typeof value === 'object') {
    const entries = Object.entries(value);
    if (entries.length === 0) return '{}';
    const childIndent = indent + '  ';
    const lines = entries.map(([k, v]) => {
      if (Array.isArray(v) && v.length > 5) {
        const itemIndent = childIndent + '  ';
        const arrayLines = v.map((item) => `${itemIndent}${JSON.stringify(item)}`);
        const formattedArray = `[\n${arrayLines.join(',\n')}\n${childIndent}]`;
        return `${childIndent}${JSON.stringify(k)}: ${formattedArray}`;
      }
      return `${childIndent}${JSON.stringify(k)}: ${formatApiResult(v, childIndent)}`;
    });
    return `{\n${lines.join(',\n')}\n${indent}}`;
  }
  return JSON.stringify(value);
}

/**
 * Prints the API result to stdout (or stderr if marked as failure or operationResult.successful is false).
 */
export function printApiResult(result: unknown, asFailure = false): void {
  const isFailed =
    asFailure ||
    (typeof result === 'object' &&
      result !== null &&
      'operationResult' in result &&
      (result as { operationResult?: { successful?: boolean } }).operationResult?.successful === false);

  const formatted = formatApiResult(result);
  if (isFailed) {
    console.error(formatted);
  } else {
    console.log(formatted);
  }
}

/**
 * Masks a sensitive token string, showing only prefix and suffix.
 */
export function maskToken(token: string | null | undefined): string {
  if (!token) return '<none>';
  if (token.length <= 16) return '********';
  return `${token.substring(0, 10)}...${token.substring(token.length - 6)}`;
}
