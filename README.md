# bootstrap

Automated development environment and home server bootstrapping.

## Installation

```bash
curl https://raw.githubusercontent.com/ambruss/bootstrap/master/bootstrap.sh | bash
```

## Options

To pass args through the piped bootstrap script to `setup-dev.sh`:

```bash
curl $URL | bash -s -- --include python
```

The available options are shown in the help message:

```text
❯ ./setup-dev.sh --help
Usage: ./setup-dev.sh [OPTION...]

Automated development environment setup on Elementary OS 5.1.

Examples:
  ./setup-dev.sh --include python
  ./setup-dev.sh --include jq=1.6 --force
  ./setup-dev.sh --exclude sublime

Options:
  -l, --list                List available modules
  -i, --include MOD[=VER]   Only install explicitly whitelisted modules
                            Optionally define module version to install
  -x, --exclude MOD         Skip installing explicitly blacklisted modules
  -D, --no-deps             Skip installing module dependencies
  -f, --force               Force reinstalls even if module is already present
      --dry-run             Only print what would be installed
      --dotenv              Autocreate .env file for customizing user settings
```

## Testing

The test dependencies (including `pre-commit`) are installed via `setup-dev.sh`.

```bash
pre-commit run -a
```

## License

MIT
