# Build security checks

This repository runs secret scanning as the first DevSecOps control for the Docker image build workflow.

## Secret scanning

Secret scanning is implemented with Gitleaks in GitHub Actions. The workflow scans pull requests, pushes to the main development branches, weekly scheduled runs, and manual dispatches.

The workflow intentionally checks out the full Git history (`fetch-depth: 0`) so Gitleaks can detect secrets that may have been introduced in earlier commits, not only in the tip of a branch.

## Local usage

Run the same scanner locally before opening a pull request:

```bash
make secret-scan
```

The Makefile target uses the official Gitleaks container image and mounts the repository read-only into the scanner container.

## Handling findings

If Gitleaks reports a secret:

1. Remove the secret from the repository.
2. Rotate the exposed credential in the upstream service.
3. Re-run `make secret-scan`.
4. If the finding is a false positive, document why before adding an allowlist rule.

Do not commit real JWT secrets, TLS private keys, database passwords, API tokens, or cloud credentials. Example configuration values should use placeholders such as `<replace-with-secure-random-value>`.
