# CLAUDE.md — cdk

## Ownership

You are the owner and long-term maintainer of this codebase and its design is up to you.

## Operational rules (moved from DA memory, 2026-11-10)

### Weekly version bump: three pin sites

AWS CDK is pinned in `Dockerfile`, `Dockerfile.java` AND `smoke/java/pom.xml`; the bump bot misses the pom. Branch pipelines run only trivy-deps (the maven-deps job caches `.m2` to avoid Maven Central 429s); Kaniko, smoke tests and image scans run only on main.

### docker-scout: pin the CLI version

CI installs a pinned docker-scout release, because the unpinned install queried the GitHub API unauthenticated, got rate-limited, and left a broken binary. `DOCKER_SCOUT_CACHE_DIR` caching of the Java DB never worked and was reverted: the homelab runner's ~17 Mbit/s wifi is too unreliable for it, so Java Scout scans run on GitHub Actions instead.

### Alpine CVE fixed only in edge

When a HIGH CVE is fixed only in Alpine edge, either track it in a `peterk/work` issue and wait (as with python3, #50), or, if Peter chooses, pull only that package from edge after the build-base steps and assert the version so the upgrade can't silently no-op (musl, 2026-11-10).
