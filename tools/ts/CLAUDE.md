# TypeScript Tooling

## Scaffolding

Create a new TypeScript project:

```bash
create-ts-project.sh --framework solid|astro <project-name>
create-ts-project.sh --framework solid --no-install my-app
```

The script lives at `~/.myai/tools/scripts/create-ts-project.sh`.

## Conventions

All TypeScript projects follow the conventions in the global CLAUDE.md:

- Vite + Vitest + Oxlint (individual packages; Vite+ unified toolchain when available)
- `strict: true` always
- SolidJS for interactive UIs, Astro for content sites
- Unit tests colocated as `*.test.ts`
- Import order: node builtins → third-party → local

## Adding a Framework

1. Add an `elif` branch in `create-ts-project.sh` for the new framework
2. Emit the framework-specific `package.json`, config, and starter files
3. The shared files (tsconfig, oxlint, .gitignore) are emitted for all frameworks
