# Changelog

## [2026-06-23]

### Security
- Added an accepted-risk exception (OpenVEX, `.vex/cve-2025-60876.openvex.json`) for
  **CVE-2025-60876** — BusyBox `wget` request-line splitting / header injection (MEDIUM, CVSS 6.5).
  Status `not_affected` / `vulnerable_code_not_in_execute_path`: the cdk entrypoint never invokes
  BusyBox `wget`, and the only build-time `wget` use fetches fixed `registry.npmjs.org` URLs. **No
  fixed busybox exists in any Alpine branch yet** — the Dockerfile's `apk upgrade` will clear it
  automatically once Alpine ships a patch. The VEX is consumed by the Scout GitHub action via
  `vex-location`. Remove the statement once a fixed busybox lands.

## [2026-06-22] - `pkumaschow/cdk:latest`, `gitlab.homelab.com:5050/peterk/cdk:latest`

### Security
- Security refresh — the published image was ~2 months stale and Docker Scout flagged fixable
  HIGH/MEDIUM CVEs. Local trivy rescan of a fresh rebuild: **40 → 2** fixable HIGH/MEDIUM.
- Generalised the bundled-dep patch (previously picomatch-only) to also patch **brace-expansion**
  (CVE-2026-33750, CVE-2026-45149) and **ip-address** (CVE-2026-42338) in place across all nested
  `node_modules` — verified cleared.
- OS/apk CVEs (libcrypto3/libssl3, libexpat, musl, nghttp2-libs, libcurl, tar, xz-libs) cleared by
  `apk upgrade`; `urllib3` pinned ≥2.7.0 (CVE-2026-44431, CVE-2026-44432) — verified cleared.
- Added an **undici** patch (toward latest 6.x — CVE-2026-12151 DoS, CVE-2026-9679 header
  injection). undici is bundled inside **npm itself**; the patch computes and asserts 6.27.0 during
  the build but does **not** persist under local rootless podman (an overlayfs/bundled-dependency
  quirk). Retained so the CI Kaniko build + Scout can determine whether it clears there. Low
  runtime risk: npm's HTTP client is not exercised by the `cdk` entrypoint. Tracking an upstream
  npm bump as the durable fix.

### Changed
- AWS CDK CLI: 2.1124.1 → **2.1128.0**
- aws-cdk-lib: 2.257.0 → **2.260.0**

## [2026-05-25] - `pkumaschow/cdk:latest`, `gitlab.homelab.com:5050/peterk/cdk:latest`

### Changed
- AWS CDK CLI: 2.1115.1 → **2.1124.1**
- aws-cdk-lib: 2.246.0 → **2.257.0**
- README refreshed — removed stale Python 3.7.9 claim and orphaned "needs more work" note; added GitLab homelab registry pull instructions and a TypeScript example alongside Python.
- `ci.sh` repurposed as a local-build convenience (no more GoCD `/godata/pipelines` path).

### CI/CD
- Added `.gitlab-ci.yml` with a Kaniko-based build that pushes to the homelab GitLab container registry at `gitlab.homelab.com:5050/peterk/cdk` with three tags per build: `:latest`, `:<cdk-version>`, `:<short-sha>`.
- Added a Docker Scout CVE scan stage to the GitLab pipeline (gates the build on fixable HIGH/CRITICAL findings via `--only-fixed --exit-code`).
- Pinned all GitHub Actions in `docker-publish.yml` to commit SHAs (`actions/checkout`, `docker/setup-buildx-action`, `docker/login-action`, `docker/build-push-action`, `docker/scout-action`) to harden the supply chain.
- Added `.dockerignore` — keeps `.git`, CI metadata, README/CHANGELOG/LICENSE and local dotfiles out of the build context.

## [2026-04-08] - `pkumaschow/cdk:latest`

### Changed
- AWS CDK CLI: unpinned → 2.1115.1
- aws-cdk-lib: unpinned → 2.246.0

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
