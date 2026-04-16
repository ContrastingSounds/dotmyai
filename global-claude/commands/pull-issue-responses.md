---
description: Pull responses to clarification questions from Linear issue comments, summarize answers, and suggest next steps.
argument-hint: Linear issue identifier (e.g. CON-34)
---

# Pull Responses to Clarification Questions

## Input

Linear issue identifier: $ARGUMENTS

## Step 1: Parse the Issue Identifier

Extract the issue identifier from the input. Accepted formats:
- Full URL: `https://linear.app/{workspace}/issue/{ID}/...` → extract `{ID}` (e.g., `CON-34`)
- Short identifier: `CON-34` → use directly

If the input does not match either format, ask the user for a valid Linear issue URL or identifier.

## Step 2: Fetch the Issue and Comments

1. Use `mcp__claude_ai_Linear__get_issue` with `includeRelations: true` to retrieve the issue details.
2. Use `mcp__claude_ai_Linear__list_comments` to retrieve all comments on the issue.

If the issue cannot be found, inform the user and stop.

## Step 3: Identify Question-Response Pairs

Analyze the comments chronologically. Identify:
- **Questions**: Comments that contain clarification questions (typically posted by the bot/agent, often formatted with bold headings like `**Q1: ...**` or numbered lists).
- **Responses**: Comments that follow questions and provide answers (typically posted by a different author or as replies).

For each question, determine:
- Whether it has been answered
- The substance of the answer
- Whether the answer is clear or needs follow-up

## Step 4: Present a Summary

Present the findings in this format:

```
## Responses Summary for {ISSUE-ID}: {Issue Title}

### Answered Questions
For each answered question:
- **Q: [question summary]**
  **A:** [response summary]

### Unanswered Questions
For each unanswered question:
- **Q: [question summary]**
  *(No response yet)*

### Ambiguous / Needs Follow-up
For any answers that are unclear or partial:
- **Q: [question summary]**
  **A:** [what was said]
  **Follow-up needed:** [what remains unclear]
```

## Step 5: Resolve Answered Comment Threads

Proactively resolve each satisfactorily answered question thread — do not wait for user confirmation:

1. For each answered question comment, use `mcp__claude_ai_Linear__save_comment` with `parentId` set to the question comment's ID to post a threaded reply summarizing the resolution:
   ```
   ✅ **Resolved** — [1-2 sentence summary of the answer and any decisions made]
   ```
2. Only resolve threads where the answer is clear and complete. Do not resolve threads flagged as ambiguous or needing follow-up.
3. Report how many threads were resolved and how many remain open.

## Step 6: Suggest Next Steps

Based on the state of responses:

- **All answered**: Suggest updating the issue description with consolidated requirements, or proceeding to implementation planning.
- **Some unanswered**: List which questions still need answers and suggest the user respond to those before proceeding.
- **Ambiguous answers**: Propose specific follow-up questions to post as new comments for clarification.

## Rules

- **Read-only except thread resolution**: Do not update the issue description or post new top-level comments unless the user explicitly asks. Answered comment threads are resolved proactively (Step 5) without confirmation.
- **Preserve nuance**: When summarizing answers, capture the specific choices and reasoning, not just yes/no.
- **Flag conflicts**: If answers contradict each other or conflict with the existing issue description, call this out.
- **Context-aware**: If the issue has sub-issues, mention them so the user can decide whether answers should propagate to sub-issue requirements.
