# skills

## Quick Install

Install skills from this repository with `npx skills add`:

```bash
# list available skills
npx skills add sonofmagic/skills --list

# install one skill
npx skills add sonofmagic/skills --skill weapp-vite-best-practices -y

# install multiple skills
npx skills add sonofmagic/skills \
  --skill wevu-best-practices \
  --skill weapp-vite-best-practices \
  -y

# install all skills in this repository
npx skills add sonofmagic/skills --all -y
```

Available skills currently include:

- `weapp-tailwindcss`
- `native-to-weapp-vite-wevu-migration`
- `weapp-vite-best-practices`
- `weapp-vite-vue-sfc-best-practices`
- `wevu-best-practices`

Tip: `npx skills@latest ...` is optional. Prefer `npx skills ...` for regular usage.

## Packages

## Contributing

Contributions Welcome! You can contribute in the following ways.

- Create an Issue - Propose a new feature. Report a bug.
- Pull Request - Fix a bug and typo. Refactor the code.
- Create third-party middleware - Instruct below.
- Share - Share your thoughts on the Blog, X, and others.
- Make your application - Please try to use skills.

For more details, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Centralized Upstream Skills Sync

This repository uses a centralized pull-based sync mode to collect skill content from multiple upstream repositories into this target repository.

- Trigger workflow: `.github/workflows/sync-from-upstreams.yml`
- Source config: `.github/skills-sources.json`
- Public upstream repositories usually do not require extra tokens.
- If an upstream repository is private, configure an optional read-only token in this repository as `UPSTREAM_READ_TOKEN`.

## Rewrite Git History (Dangerous)

Use this only when you intentionally want to discard old git history and keep a single fresh commit on the remote branch.

Local run:

```bash
pnpm script:rewrite-history -- --target-branch main --yes
```

Dry run:

```bash
pnpm script:rewrite-history -- --target-branch main --dry-run
```

GitHub Actions manual trigger:

1. Open `Actions` -> `Rewrite History`.
2. Click `Run workflow`.
3. Fill inputs and run.

After a successful rewrite, all collaborators must re-clone the repository.

## Contributors

Thanks to [all contributors](https://github.com/sonofmagic/skills/graphs/contributors)!

## Authors

ice breaker <1324318532@qq.com>

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
