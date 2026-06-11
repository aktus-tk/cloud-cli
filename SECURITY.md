# Security Policy

## Reporting Security Issues

If you discover a security vulnerability in this project, please report it by emailing:

**y.takeaki@gmail.com**

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will respond as quickly as possible and work with you to address the issue.

## Security Best Practices

### Authentication and Credentials

**IMPORTANT**: This tool collection (`awst`, `gcloudt`, `tcclit`) does NOT store or manage cloud credentials directly.

Authentication is handled entirely by the underlying cloud CLI tools:
- **AWS**: `aws` CLI (uses `~/.aws/credentials` and `~/.aws/config`)
- **GCP**: `gcloud` CLI (uses `~/.config/gcloud/`)
- **Tencent Cloud**: `tccli` (uses `~/.tccli/`)

### Recommended Practices

1. **Credential Management**
   - Never hardcode credentials in scripts or configuration files
   - Use IAM roles and instance profiles when running on cloud instances
   - Use credential management tools provided by each cloud provider
   - Rotate credentials regularly

2. **Access Control**
   - Follow the principle of least privilege
   - Use separate credentials for different environments (dev/staging/prod)
   - Enable MFA (Multi-Factor Authentication) on your cloud accounts

3. **Safe Usage**
   - Always review commands before execution, especially destructive operations (delete, stop, etc.)
   - Use `--dry-run` or preview modes when available
   - Test scripts in non-production environments first
   - Be cautious with CSV export features - they may contain sensitive information

4. **Debug Mode**
   - Some commands support `--debug` flag for troubleshooting
   - Debug output may include API requests and responses
   - **Never share debug logs publicly** - they may contain sensitive data

5. **Git Hygiene**
   - Never commit `.env` files or credential files to version control
   - Review `.gitignore` to ensure sensitive files are excluded
   - Use `git log` and `git diff` to review changes before committing

## Supported Versions

This project provides security updates for the latest version only. We recommend always using the most recent version from the `main` branch.

## Known Limitations

- These tools inherit security characteristics from underlying CLI tools (`aws`, `gcloud`, `tccli`)
- Output may contain sensitive information (instance IDs, IP addresses, etc.) - handle with care
- Some commands require elevated IAM permissions - review cloud provider documentation

## Security Updates

We will announce security updates through:
- GitHub Security Advisories
- Commit messages with `[SECURITY]` prefix
- Release notes for tagged versions

## Disclaimer

These tools are provided as-is for convenience and productivity. Users are responsible for:
- Securing their own cloud credentials
- Following their organization's security policies
- Understanding the permissions and access levels of commands they execute
- Reviewing and testing code before use in production environments
