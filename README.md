# skills

## Packages

## Contributing

Contributions Welcome! You can contribute in the following ways.

- Create an Issue - Propose a new feature. Report a bug.
- Pull Request - Fix a bug and typo. Refactor the code.
- Create third-party middleware - Instruct below.
- Share - Share your thoughts on the Blog, X, and others.
- Make your application - Please try to use skills.

For more details, see [CONTRIBUTING.md](CONTRIBUTING.md).

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
