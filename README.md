# This repository is ⚰️ ARCHIVED ⚰️

`pronto-flow` no longer falls in my interestes and I cannot give it any time in keeping it updated. With `flow` ever changing the logic for parsing the changing json output of that tool is a moving target. I've also made the decision to use TypeScript over Flow for future JavaScript projects.

Feel free to fork and take the project in a new direction. You could also contact me to unarchive it if you are willing to maintain it.

-----

# Pronto runner for flow (using flow from npm)

[![Gem Version](https://badge.fury.io/rb/pronto-flow.svg)](http://badge.fury.io/rb/pronto-flow)
[![Build Status](https://travis-ci.org/kevinjalbert/pronto-flow.svg?branch=master)](https://travis-ci.org/kevinjalbert/pronto-flow)
[![Code Climate](https://codeclimate.com/github/kevinjalbert/pronto-flow/badges/gpa.svg)](https://codeclimate.com/github/kevinjalbert/pronto-flow)
[![Test Coverage](https://codeclimate.com/github/kevinjalbert/pronto-flow/badges/coverage.svg)](https://codeclimate.com/github/kevinjalbert/pronto-flow/coverage)
[![Dependency Status](https://gemnasium.com/badges/github.com/kevinjalbert/pronto-flow.svg)](https://gemnasium.com/github.com/kevinjalbert/pronto-flow)

Pronto runner for [flow](https://flow.org/), a static type checker for javascript. [What is Pronto?](https://github.com/mmozuras/pronto)

Uses official flow executable installed by `npm`.

## Prerequisites

You'll need to install [flow by yourself with npm](https://flow.org/en/docs/install/). If `flow` is in your `PATH`, everything will simply work, otherwise you have to provide pronto-flow your custom executable path (see [below](#configuration-of-pronto-flow)).

## Configuration of flow

Configuring flow via [.flowconfig](https://flow.org/en/docs/config/) will work just fine with pronto-flow.

## Configuration of pronto-flow

pronto-flow can be configured by placing a `.pronto_flow.yml` inside the directory where pronto is run.

Following options are available:

| Option               | Meaning                                | Default                                   |
| -------------------- | -------------------------------------- | ----------------------------------------- |
| flow_executable      | flow executable to call.               | `flow` (calls `flow` in `PATH`)           |
| cli_options          | Options to pass to the CLI.            | `--json`                                  |

Example configuration to call custom flow executable:

```yaml
# .pronto_flow.yml
flow_executable: '/my/custom/node/path/.bin/flow'
cli_options: '--show-all-errors'
```
