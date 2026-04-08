# Changelog

## [2026-04-08] - `pkumaschow/cdk:latest`

### Changed
- AWS CDK CLI: unpinned → 2.1117.0
- aws-cdk-lib: unpinned → 2.1117.0

## [2026-04-01] - `pkumaschow/cdk:latest`

### Changed
- Base image updated from `alpine:3.12` + manual Node/Python builds to `node:22-alpine`
  - Node.js: 14.13.1 → 22 LTS
  - Python: 3.7.9 (built from source) → 3.12 (via Alpine apk)
  - Removed ~220 lines of from-source build complexity
- Alpine base unpinned from `node:22-alpine3.21` to `node:22-alpine` to track latest security patches
- `apk upgrade --no-cache` added to apply all OS-level security patches at build time
- AWS CDK: v1 (individual pip packages) → v2 (`aws-cdk-lib` + `constructs`)
- npm updated to latest at build time to resolve bundled dependency CVEs
- Added non-root user (`node`, uid 1000) as default runtime user
- Removed Yarn installation (not required for CDK usage)

### Security
- **CVE-2025-15467** (CRITICAL) — OpenSSL: Remote code execution via oversized Initialization Vector; fixed by `apk upgrade` → `libcrypto3`/`libssl3` 3.5.5-r0
- **CVE-2025-69419** (HIGH) — OpenSSL: Arbitrary code execution via out-of-bounds write in PKCS#12 processing; fixed by `apk upgrade`
- **CVE-2025-69421** (HIGH) — OpenSSL: Denial of Service via malformed PKCS#12 file; fixed by `apk upgrade`
- **CVE-2026-23745** (HIGH) — node-tar: Arbitrary file overwrite via symlink poisoning; fixed by `npm@latest` (bundles tar ≥ 7.5.3)
- **CVE-2026-23950** (HIGH) — node-tar: Arbitrary file overwrite via Unicode path collision race condition; fixed by `npm@latest` (bundles tar ≥ 7.5.4)
- **CVE-2026-24842** (HIGH) — node-tar: Arbitrary file creation via hardlink path traversal bypass; fixed by `npm@latest` (bundles tar ≥ 7.5.7)
- **CVE-2026-26960** (HIGH) — node-tar: Arbitrary file read/write via malicious archive hardlink creation; fixed by `npm@latest` (bundles tar ≥ 7.5.8)
- **CVE-2026-29786** (HIGH) — node-tar: Hardlink path traversal via drive-relative linkpath; fixed by `npm@latest` (bundles tar ≥ 7.5.10)
- **CVE-2026-31802** (HIGH) — node-tar: File overwrite via drive-relative symlink traversal; fixed by `npm@latest` (bundles tar ≥ 7.5.11)
- **CVE-2026-33671** (HIGH) — picomatch: ReDoS via extglob patterns (`+(a|aa)`, `+(*|?)` etc.); fixed by patching all nested picomatch instances (including aws-cdk bundled copies) to latest via tarball replacement
- **CVE-2026-24049** (HIGH) — wheel/setuptools: Path traversal in `wheel.cli.unpack` — chmod applies unsanitized archive filename allowing permission modification outside extraction directory; fixed by `pip3 install --upgrade wheel setuptools`

### CI/CD
- Replaced `elgohr/Publish-Docker-Github-Action` with `docker/build-push-action@v6`
- Added Docker layer caching via GitHub Actions cache
- Added SLSA provenance attestation (`provenance: mode=max`) on main branch builds
- Added SBOM attestation (`sbom: true`) on main branch builds
- Integrated Docker Scout: vulnerability comparison on PRs, CVE recording on main
- Publish now triggers only on pushes to `main` (previously all branches)
