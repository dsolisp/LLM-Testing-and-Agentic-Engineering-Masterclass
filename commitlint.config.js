// commitlint.config.js — identical across all 5 repos
// SYNC-MANAGED — do not edit in project repos. Edit in shared-docs/ and run sync-standards.sh
// See: shared-docs/docs/adr/ADR-013-multirepo-sync-strategy.md

/** @type {import('@commitlint/types').UserConfig} */
module.exports = {
  extends: ["@commitlint/config-conventional"],

  rules: {
    // Enforce all conventional commit types
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "docs", "style", "refactor", "test", "chore", "ci", "perf", "revert"],
    ],

    // Scope is optional but must be lowercase if provided
    "scope-case": [2, "always", "lower-case"],

    // Subject must not end with a period
    "subject-full-stop": [2, "never", "."],

    // Subject must be in lower-case
    "subject-case": [2, "always", "lower-case"],

    // Subject max 100 chars
    "subject-max-length": [2, "always", 100],

    // Header max 120 chars
    "header-max-length": [2, "always", 120],

    // Body lines max 120 chars
    "body-max-line-length": [2, "always", 120],
  },

  // Prompt configuration (commitizen)
  prompt: {
    questions: {
      type: {
        description: "Select the type of change",
        enum: {
          feat:     { description: "A new feature",                     title: "Features" },
          fix:      { description: "A bug fix",                         title: "Bug Fixes" },
          docs:     { description: "Documentation only changes",        title: "Documentation" },
          style:    { description: "Formatting, missing semi-colons",   title: "Styles" },
          refactor: { description: "Code change (no feature or fix)",   title: "Code Refactoring" },
          test:     { description: "Adding or correcting tests",        title: "Tests" },
          chore:    { description: "Changes to the build process / aux tools", title: "Chores" },
          ci:       { description: "CI/CD pipeline changes",            title: "CI" },
          perf:     { description: "Performance improvement",           title: "Performance" },
          revert:   { description: "Reverts a previous commit",        title: "Reverts" },
        },
      },
      scope: {
        description: "Scope of the change (e.g. login, cart, dropdown, ci)",
      },
      subject: {
        description: "Short description (imperative, lower-case, no period)",
      },
      body: {
        description: "Longer description (optional, wrap at 120 chars)",
      },
      isBreaking: {
        description: "Are there any breaking changes?",
      },
      breakingBody: {
        description: "Describe the breaking change",
      },
      breaking: {
        description: "Describe the breaking changes",
      },
      isIssueAffected: {
        description: "Does this change affect any open issues?",
      },
      issues: {
        description: "Add issue references (e.g. #123, #456)",
      },
    },
  },
};
