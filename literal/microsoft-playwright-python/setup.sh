#!/usr/bin/env bash
# literal: microsoft/playwright-python @ 86a5f5a81010b1dbd155263e99782442b61d0cb2
# readme: README.md
set -e  # glue strict mode
pip install pytest-playwright  # https://playwright.dev/python/docs/intro
playwright install  # https://playwright.dev/python/docs/intro
