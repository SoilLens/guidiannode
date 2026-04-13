class AppError extends Error {
  constructor(message, statusCode = 500, code = 'internal_error', details = null) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

const isMissingRelationError = (error, relationName) => {
  const haystack = [
    error?.message,
    error?.details,
    error?.hint,
    error?.code,
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  const normalizedRelation = String(relationName).toLowerCase();

  return (
    haystack.includes(`relation "${normalizedRelation}"`) ||
    haystack.includes(`table "${normalizedRelation}"`) ||
    haystack.includes(`table '${normalizedRelation}'`) ||
    haystack.includes(`could not find the table '${normalizedRelation}'`) ||
    haystack.includes(`could not find the table "${normalizedRelation}"`) ||
    error?.code === 'PGRST205'
  );
};

const extractEnumMismatchValue = (error, enumName) => {
  if (error?.code !== '22P02') {
    return null;
  }

  const haystack = [error?.message, error?.details, error?.hint]
    .filter(Boolean)
    .join(' ');
  const normalizedEnumName = String(enumName).toLowerCase();

  if (!haystack.toLowerCase().includes(`enum ${normalizedEnumName}`)) {
    return null;
  }

  const match = haystack.match(/enum\s+[a-z0-9_."]+:\s+"([^"]+)"/i);
  return match?.[1] ?? null;
};

const extractMissingColumnFromSchemaCache = (error, relationName) => {
  const haystack = [error?.message, error?.details, error?.hint]
    .filter(Boolean)
    .join(' ');
  const normalizedRelationName = String(relationName).toLowerCase();
  const match = haystack.match(
    /could not find the ['"]([^'"]+)['"] column of ['"]([^'"]+)['"] in the schema cache/i
  );

  if (!match) {
    return null;
  }

  const [, columnName, reportedRelationName] = match;
  return reportedRelationName.toLowerCase() === normalizedRelationName
    ? columnName
    : null;
};

const extractSupabaseConnectivityIssue = (error) => {
  const haystack = [error?.message, error?.details, error?.hint]
    .filter(Boolean)
    .join(' ');
  const normalizedHaystack = haystack.toLowerCase();

  if (!normalizedHaystack.includes('fetch failed')) {
    return null;
  }

  const hostMatch =
    haystack.match(/getaddrinfo\s+(?:eai_again|enotfound)\s+([a-z0-9.-]+)/i) ||
    haystack.match(/https?:\/\/([a-z0-9.-]+)/i);
  const host = hostMatch?.[1] ?? null;

  if (normalizedHaystack.includes('eai_again')) {
    return {
      host,
      reason: 'dns_temporary_failure',
    };
  }

  if (normalizedHaystack.includes('enotfound')) {
    return {
      host,
      reason: 'dns_not_found',
    };
  }

  if (normalizedHaystack.includes('etimedout')) {
    return {
      host,
      reason: 'network_timeout',
    };
  }

  if (
    normalizedHaystack.includes('econnrefused') ||
    normalizedHaystack.includes('network is unreachable')
  ) {
    return {
      host,
      reason: 'network_unreachable',
    };
  }

  return {
    host,
    reason: 'fetch_failed',
  };
};

const extractForeignKeyConstraintName = (error) => {
  if (error?.code !== '23503') {
    return null;
  }

  const haystack = [error?.message, error?.details, error?.hint]
    .filter(Boolean)
    .join(' ');
  const match = haystack.match(/foreign key constraint "([^"]+)"/i);

  return match?.[1] ?? null;
};

const wrapDatabaseError = (error, relationName) => {
  if (isMissingRelationError(error, relationName)) {
    return new AppError(
      `Database table "${relationName}" is missing. Apply the SQL setup file and retry.`,
      500,
      'database_relation_missing',
      error
    );
  }

  const supabaseConnectivityIssue = extractSupabaseConnectivityIssue(error);

  if (supabaseConnectivityIssue) {
    const hostSuffix = supabaseConnectivityIssue.host
      ? ` Host: ${supabaseConnectivityIssue.host}.`
      : '';

    return new AppError(
      `Supabase connectivity error.${hostSuffix} The backend could not reach the configured SUPABASE_URL. Verify the project URL, internet connection, DNS resolution, VPN/proxy settings, and Supabase service availability, then retry.`,
      503,
      'database_connectivity_error',
      error
    );
  }

  const missingColumnName =
    extractMissingColumnFromSchemaCache(error, relationName);

  if (missingColumnName) {
    return new AppError(
      `Database schema cache mismatch detected. The "${missingColumnName}" column for "${relationName}" is not available through the Supabase schema cache yet. If the column is missing, apply server/sql/add_enum_value.sql. If the column already exists, run server/sql/reload_schema_cache.sql and retry.`,
      500,
      'database_column_missing',
      error
    );
  }

  const otpPurposeEnumMismatchValue =
    extractEnumMismatchValue(error, 'otp_purpose_enum');

  if (otpPurposeEnumMismatchValue) {
    return new AppError(
      `Database enum mismatch detected. The enum "otp_purpose_enum" does not support "${otpPurposeEnumMismatchValue}". Ensure backend constants match database enums and apply server/sql/add_enum_value.sql if schema drift exists.`,
      500,
      'database_enum_mismatch',
      error
    );
  }

  const foreignKeyConstraintName = extractForeignKeyConstraintName(error);

  if (relationName === 'users' && foreignKeyConstraintName === 'users_id_fkey') {
    return new AppError(
      'Database foreign key mismatch detected. The "public.users.id" value must exist in Supabase auth users before the profile row can be inserted. Provision the auth user first, then retry registration.',
      500,
      'database_foreign_key_mismatch',
      error
    );
  }

  return new AppError(
    error?.message || 'Database operation failed',
    500,
    'database_error',
    error
  );
};

module.exports = {
  AppError,
  wrapDatabaseError,
};
