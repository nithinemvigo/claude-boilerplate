# claude-boilerplate
skelton


intsall plugins
1. Superpowers — [github.com/obra/superpowers](http://github.com/obra/superpowers) 
2. Frontend Design — [claude.com/plugins/frontend-design](http://claude.com/plugins/frontend-design) 
3. Code Review — https://claude.com/plugins/code-review
4. Security Review — https://claude.com/plugins/security-guidance
5. claude-mem — [github.com/nicholasgasior/claude-mem](http://github.com/nicholasgasior/claude-mem) 
6. gstack — [github.com/garrytan/gstack](http://github.com/garrytan/gstack)

## Plugin Testing
These core plugins are now installed and enabled:
- **Superpowers**: Test with `Ask to search all logs or explore the system comprehensively`.
- **Frontend Design**: Test with `Ask Claude to design a minimalist button component`.
- **Code Review**: Test with `Ask Claude to perform a code review on a source file`.
- **Security Guidance**: Test with `Ask Claude to audit a specific module for security`.
- **Claude Mem**: Test with `Note down this project's preferred styling framework for next time`.

## Custom Skills Installation
If you have a customized or forked repository containing multiple skills, you can easily install them globally or strictly for this project.

### Step 1: Global Installation (All Projects)
1. Clone your forked repo:
   ```bash
   git clone <YOUR_FORK_URL> ~/.claude/skills/<custom-skills-folder>
   ```
2. Any setup scripts available in your fork should be run here.

### Step 2: Local Installation (This Project Only)
1. Clone into the project's local tools folder:
   ```bash
   git clone <YOUR_FORK_URL> .claude/skills/<custom-skills-folder>
   ```
2. Update the `CLAUDE.md` to reference the newly added skills so that your teammates can also use them.
