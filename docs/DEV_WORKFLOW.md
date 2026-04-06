# Development Workflow

1. Brainstorm
2. Plan
3. Develop
4. Debug
5. Test
6. CI/CD

## Brainstorm

While structured research processes are entirely possible, the goal of the
"brainstorm" phase is to allow fast, easy AI-assisted exporation of ideas.
Explicitly labelling this stage is really just a naming convention for
having a "brainstorm" folder, which is also in .gitignore to avoid polluting
the repository.

- Save artefacts to `ai/brainstorm`
- No set process or templates

## Plan

The goal of the planning stage is to generate good designs, PRDs and plans.
Plans are always required, as agentic coding is significantly more effective
after iterating over a planning document. PRDs are also useful for keeping
a clear view of the desired outcome of the coding project. 

The `ai/plans` folder might also be used to store other planning and design
artifacts.

- For "official" projects, should be associated to a Linear project or issue
- outputs to both `ai/designs` and `ai/plans` folders
- `designs` are permanent, evolving documents that represent the goal
- `plans` are temporory, frequently archived documents for meeting the goal

## Develop

For serious development tasks (but not necessarily minor ones), some form
of TODO list is necessary. All agents and IDEs provide some form of this, and
the out-of-the-box tooling is often all that is required.

Note that for product development, work must be tracked in Linear. There is no
established relationship between Linear issues and an agent's plans and todos.
The working assumptions of myai are:

- Issues in Linear ensure alignment to product roadmaps and customer commitments
- Local TODOs and .beads ensure local control of detailed coding tasks
  - They are more detailed and also more ephmeral than Linear issues
  - beads epics are "less epic" than in Linear, more akin to issues and projects
- Development may take place over session sessions and context refreshes

## Debug

tbc

## Test

Testing is the primary feedback loop for verifying agent-generated code.

- Read `ai/instructions/testing-strategy.md` for the full strategy
- Run tests after each meaningful change (catch failures early)
- Every bug fix requires a regression test
- Never weaken or skip tests to make them pass
- Always verify actual test output — don't trust summaries

## CI/CD

- AI is quite good at developing GitHub actions for CI/CD automation
