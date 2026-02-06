# CleanSlate Security Checklist

Last updated: 2025-02-05

## Overview

This document tracks security measures implemented in CleanSlate and serves as a checklist for security audits before releases.

---

## Pre-Release Security Checklist

### Database Security (Supabase/PostgreSQL)

- [x] **RLS Enabled** on all tables
  - `households`, `household_members`, `chores`, `chore_assignments`
  - `notifications`, `user_fcm_tokens`, `profiles`
  - `scheduled_assignments`, `calendar_integrations` (if exist)

- [x] **RLS Policies** properly configured
  - SELECT: Users can only read their own household's data
  - INSERT: Users can only insert to their own household
  - UPDATE: Users can only update their own data (or admins for household data)
  - DELETE: Users can only delete their own data (or admins for household data)
  - See: `supabase/security_audit_rls.sql`

- [x] **Database Constraints** enforce data integrity
  - Length limits on text fields
  - Format validation (invite codes, phone numbers)
  - Enum constraints on status/role fields
  - See: `supabase/add_column_constraints.sql`

- [x] **SQL Injection Prevention**
  - Supabase client uses parameterized queries
  - No raw SQL concatenation in client code
  - RPC function `find_household_by_code` validates input

### Authentication & Authorization

- [x] **Auth State Validation**
  - `AuthGuard.isAuthenticated()` - check user is logged in
  - `AuthGuard.isHouseholdMember()` - check membership
  - `AuthGuard.isHouseholdAdmin()` - check admin role
  - See: `lib/core/utils/auth_guard.dart`

- [x] **Session Security**
  - Supabase handles token management
  - `AuthGuard.ensureValidSession()` for session refresh
  - Auth state listener redirects on session expiry

- [x] **Server-side Admin Verification**
  - RLS policies verify admin role (not just client-side)
  - Edge Functions can verify auth header

### Input Validation & Sanitization

- [x] **Client-side Validation**
  - `InputValidator` class with validators for all input types
  - XSS pattern detection
  - Length and format validation
  - See: `lib/core/utils/input_validator.dart`

- [x] **Input Sanitization**
  - `sanitizeInput()` - general sanitization
  - `sanitizeSingleLine()` - for titles/names
  - `sanitizeChoreName()`, `sanitizeHouseholdName()`, etc.
  - HTML tag stripping, control character removal
  - See: `lib/core/utils/input_sanitizer.dart`

- [x] **Server-side Validation**
  - Database CHECK constraints
  - Edge Function input validation
  - Never trust client input

- [x] **XSS Prevention**
  - Flutter Text widgets don't execute scripts
  - No WebView or HTML widgets with user content
  - Input sanitization removes HTML tags

### API & Network Security

- [x] **Edge Function Security**
  - Input validation (UUID format, string lengths)
  - Authorization checks (household membership)
  - Error messages don't leak sensitive info
  - See: `supabase/functions/send-push-notification/index.ts`

- [x] **HTTPS Only**
  - Supabase enforces HTTPS
  - No HTTP fallbacks in code

- [x] **API Key Security**
  - Supabase URL/keys via `--dart-define` or `.env`
  - `.env` files in `.gitignore`
  - Service role key only in Edge Functions (Supabase secrets)
  - No hardcoded secrets in source code

### Local Storage Security

- [x] **Secure Storage for Sensitive Data**
  - `SecureStorageHelper` uses `flutter_secure_storage`
  - Encrypted on iOS (Keychain) and Android (EncryptedSharedPreferences)
  - See: `lib/core/utils/secure_storage_helper.dart`

- [x] **SharedPreferences for Non-sensitive Data**
  - Theme preference, onboarding flag
  - No tokens or PII in SharedPreferences

- [x] **Clear on Logout**
  - `SecureStorageHelper.clearAllOnLogout()` must be called
  - Supabase SDK clears its own tokens

- [x] **Debug Logging**
  - `debugLog()` only outputs in debug mode
  - No tokens, passwords, or PII in logs
  - Production builds strip debug code

### Build Security

- [x] **Android Release Build**
  - `isMinifyEnabled = true` (ProGuard)
  - `isShrinkResources = true`
  - Flutter obfuscation via `--obfuscate --split-debug-info`

- [ ] **iOS Release Build** (TODO when ready)
  - Bitcode enabled
  - Strip debug symbols

---

## Security Files Reference

| File | Purpose |
|------|---------|
| `supabase/security_audit_rls.sql` | RLS policies for all tables |
| `supabase/add_column_constraints.sql` | Database CHECK constraints |
| `lib/core/utils/auth_guard.dart` | Auth verification helpers |
| `lib/core/utils/input_validator.dart` | Form validation |
| `lib/core/utils/input_sanitizer.dart` | Input sanitization |
| `lib/core/utils/secure_storage_helper.dart` | Encrypted local storage |
| `lib/core/utils/debug_logger.dart` | Safe debug logging |

---

## Security Testing

### Manual Tests to Perform

1. **RLS Test**: Use Supabase SQL Editor to try querying another user's chores
   ```sql
   -- Should return empty if RLS is working
   SELECT * FROM chores WHERE household_id = '<other-household-id>';
   ```

2. **Admin Test**: Try admin actions (invite, remove member) as non-admin user
   - Should fail with permission error

3. **Input Test**: Try submitting chore with XSS payload
   - Title: `<script>alert('xss')</script>`
   - Should be sanitized/rejected

4. **Auth Test**: Try API calls without authentication
   - Should fail with 401/403

5. **Invite Code Test**: Try invalid formats
   - Too short, too long, special characters
   - Should reject with validation error

### Automated Tests (TODO)

- [ ] Unit tests for `InputValidator`
- [ ] Unit tests for `AuthGuard`
- [ ] Integration tests for RLS policies

---

## Ongoing Security Practices

### Development

- [ ] Review new code for security issues in PRs
- [ ] Update dependencies regularly (`flutter pub upgrade`)
- [ ] Check for security advisories on dependencies

### Operations

- [ ] Monitor Supabase auth logs for suspicious activity
- [ ] Review Edge Function invocation logs
- [ ] Keep Firebase/Supabase SDKs updated

### Incident Response

1. If a vulnerability is discovered:
   - Document the issue
   - Assess impact
   - Develop and test fix
   - Deploy fix
   - Notify affected users if necessary

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-02-05 | Initial security audit and hardening |
