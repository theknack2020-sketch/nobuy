#!/usr/bin/env node
// NoBuy's theme generator invocation.
//
// The colour generator itself is shared (`~/.agents/ops/gen-theme.mjs`) and takes arguments;
// `design-preflight`'s drift check runs an app's generator with NO arguments, from the app
// directory, and compares the regenerated output byte-for-byte against what is committed.
// This wrapper is where NoBuy's arguments live, so both callers work:
//
//   node Tools/gen-theme.mjs           # what the drift gate runs
//   node Tools/gen-theme.mjs --dry-run # preview without writing
//
// Regenerate after ANY token change. If this produces a diff, the tokens and the shipped theme
// have drifted apart and the tokens win — they are the single source of colour.

import { spawnSync } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';

const OPS = path.join(os.homedir(), '.agents', 'ops', 'gen-theme.mjs');

const args = [
  OPS,
  '--tokens', '.design/rounds/r2/tokens/tokens.json',
  '--catalog', 'Resources/Assets.xcassets/Colors',
  '--swift', 'Sources/Extensions/NoBuyTheme.swift',
  '--enum', 'NoBuyTheme',
  '--test', 'Tests/NoBuyThemeResolutionTests.swift',
  ...process.argv.slice(2),
];

const r = spawnSync(process.execPath, args, { stdio: 'inherit' });
process.exit(r.status ?? 2);
