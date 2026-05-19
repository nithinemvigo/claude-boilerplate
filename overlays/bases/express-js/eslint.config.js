const js = require('@eslint/js');
const prettierConfig = require('eslint-config-prettier');
const globals = require('globals');

module.exports = [
  js.configs.recommended,
  prettierConfig,
  {
    ignores: ['node_modules/**', '.reviews/**', 'coverage/**', 'dist/**'],
  },
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2024,
      sourceType: 'commonjs',
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    rules: {
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'no-console': 'off',
      eqeqeq: ['error', 'always'],
      'no-var': 'error',
      'prefer-const': 'error',
      'no-throw-literal': 'error',
      'prefer-template': 'warn',
    },
  },
];
