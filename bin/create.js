#!/usr/bin/env node
'use strict';

const { execFileSync } = require('child_process');
const path = require('path');

const REPO_ROOT = path.join(__dirname, '..');
const APPLY = path.join(REPO_ROOT, 'scripts', 'apply.sh');

const args = process.argv.slice(2);

// 'list' shorthand
if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    console.log(`
  Usage:
    npx create-claude-boilerplate <base> <project-dir> [integrations...] [--dry] [--force]
    npx create-claude-boilerplate list

  Examples:
    npx create-claude-boilerplate express-js my-api
    npx create-claude-boilerplate express-js my-api firebase prisma
    npx create-claude-boilerplate nextjs-ts ../apps/dashboard tailwind supabase
    npx create-claude-boilerplate express-js my-api --dry
    npx create-claude-boilerplate list
  `);
    process.exit(0);
}

if (args[0] === 'list') {
    execFileSync('bash', [APPLY, '--list'], { stdio: 'inherit' });
    process.exit(0);
}

if (args.length < 2) {
    console.error('Error: You must provide both a <base> and a <project-dir>.');
    process.exit(1);
}

const [base, target, ...rest] = args;

const integrations = rest.filter(a => !a.startsWith('--'));
const flags = rest.filter(a => a.startsWith('--'));

const applyArgs = [`--base=${base}`];
if (integrations.length > 0) {
    applyArgs.push(`--integrations=${integrations.join(',')}`);
}
applyArgs.push(...flags);
applyArgs.push(target);

console.log(`\n→ bash scripts/apply.sh ${applyArgs.join(' ')}\n`);
execFileSync('bash', [APPLY, ...applyArgs], { stdio: 'inherit' });
