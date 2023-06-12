/* eslint-env node */
require('@rushstack/eslint-patch/modern-module-resolution')

module.exports = {
  env: {
    browser: true,
    es2021: true,
    jquery: true,
    node: true
  },
  extends: [
    'eslint:recommended',
    'plugin:vue/vue3-essential',
    '@vue/typescript/recommended'
  ],
  parser: 'vue-eslint-parser',
  parserOptions: {
    parser: '@typescript-eslint/parser'
  },
  plugins: ['@typescript-eslint'],
  rules: {
    'comma-spacing': ['error', {'before': false, 'after': true}],
    'comma-style': ['error', 'last'],
    'dot-notation': ['error', { 'allowPattern': '^[A-Z]' }],
    'indent': ['error', 2],
    'no-unused-vars': 'off',
    'object-shorthand': ['error', 'properties'],
    '@typescript-eslint/no-unused-vars': ['warn', { 'varsIgnorePattern': '^_', 'argsIgnorePattern': '^_' }],
    '@typescript-eslint/ban-ts-comment': ['error', { 'ts-ignore': 'allow-with-description' }],
    'vue/html-closing-bracket-spacing': 0,
    'vue/max-attributes-per-line': 0,
    'vue/multi-word-component-names': 'off',
    'vue/singleline-html-element-content-newline': 0
  }
}
