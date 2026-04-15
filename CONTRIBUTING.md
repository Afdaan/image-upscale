# Contributing to image-upscale

Thank you for your interest in contributing!

## Reporting bugs

Open an issue using the **Bug report** template. Include:
- Your OS and Python version
- The exact command you ran
- The full error output or unexpected behavior

## Suggesting features

Open an issue using the **Feature request** template. Describe what you want and why it would be useful.

## Submitting a pull request

1. Fork the repo and create a branch from `main`.
2. Make your changes. Keep commits focused — one logical change per commit.
3. Test your changes:
   ```bash
   pipx install --force .
   upscale --help
   upscale /path/to/test-image.jpg
   ```
4. Open a pull request against `main` and fill in the PR template.

## Development setup

```bash
git clone https://github.com/ChrisTitusTech/image-upscale
cd image-upscale
python -m venv .venv
source .venv/bin/activate
pip install -e .
```

## Code style

- Standard Python formatting — keep it readable.
- No external linting configuration is enforced; just match the style of the surrounding code.
- Avoid adding new dependencies unless absolutely necessary. The vendored Real-ESRGAN code is intentionally minimal.

## License

By contributing you agree that your contributions will be licensed under the [MIT License](LICENSE).
