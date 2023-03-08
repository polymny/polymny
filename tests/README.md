# Polymny Studio tests

This directory contains the tests for Polymny Studio.

## Setup test environment

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run tests

```bash
pytest --tracing=on
```

## Trace tests

```bash
playwright show-trace test-results/*/trace.zip
```