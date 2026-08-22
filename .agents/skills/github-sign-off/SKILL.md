---
name: github-sign-off
description: Contributing sign-off. Use this whenever creating or replying to a GitHub Issue, Pull Request (PR), or crafting a git commit message
---

# Instructions
1. **Sign-off**: You MUST include a 🤖 (robot emoji) at the end of any commit message, Issue description, Pull Request description, or GitHub comment you post or reply to.
2. **Identity**: State your model name and version if you have access to that information natively.
3. **No Hallucination**: If you do not have your exact model string, do not guess, do not hallucinate, and do not look for it in local project files; they can target multiple LLM providers. Simply omit the model information and just sign-off with the robot emoji.
4. **Placement for Issues/PRs**: Append the tracking block to the very end of your comment, issue body, or PR description.
5. **Placement for Commits**: Append the tracking block to the body of the git commit message, separated from the commit title.

### Expected Format
```
[title]
[description]

🤖 [model and version]
```
