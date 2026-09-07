# Jon's Pipi Labu Setup — Tomorrow Morning

Do these in order. Keep one Codex task open and finish each checkpoint before moving to the next.

Shared Google Doc: <https://docs.google.com/document/d/1KzwPfXaFY1etcvu32myrPCXov9NmM7fb02BrFn2Id04/edit>

## 1. Claim both student benefits first (15 minutes)

1. Sign into the **personal ChatGPT account you intend to keep after UConn**. Do not make your UConn address the permanent account login just for this offer.
2. Claim **four free months of ChatGPT Plus** at <https://chatgpt.com/students/2026/>. Use your UConn email only when SheerID asks for school verification. The claim deadline is October 31, 2026.
3. Claim the separate **$100 of Codex credits** at <https://chatgpt.com/codex/students/>. These are 2,500 credits and expire 12 months after they are granted.
4. Save the confirmation pages and note the renewal date. Plus renews at the normal paid rate after the promotion unless canceled.

### What UConn can and cannot restrict

OpenAI explicitly allows the ChatGPT login email to differ from the school email used by SheerID. If you claim the offers from your personal ChatGPT account and use UConn only to prove current enrollment, the resulting personal workspace is not UConn's institution-managed ChatGPT Edu workspace. UConn's separately licensed Edu workspace can have university-managed access tiers and usage controls, so do not put this project there if you are about to unregister.

UConn course rules still apply to schoolwork, UConn email remains university property, and UConn says not to put FERPA, HIPAA, confidential, or embargoed material into third-party AI tools. None of that restricts this private Roblox project when you use your personal account and non-UConn project data.

## 2. Install Codex and give it one clear job (15 minutes)

1. Download the Codex app from <https://openai.com/codex> and sign into that same personal ChatGPT account.
2. Use **Full Access** for this trusted local project so Codex can inspect files, install tools, and configure Studio without stopping for routine approvals.
3. Open one task named `Set up Pipi Labu`.
4. Give it the full `JON_CODEX_BOOTSTRAP_BRIEF.md` from Leo's shared document, or tell Codex to read the shared Google Doc/email.
5. Paste this as the first instruction:

> Set up my computer for Pipi Labu end to end using this brief. Work through one checkpoint at a time and tell me when each is verified. Inspect and configure routine prerequisites yourself. Stop only when I must personally sign in, complete 2FA/CAPTCHA, choose between materially different options, or approve an irreversible external action. Do not create a fake or empty repository while Leo's current source handoff is pending. Do not configure XSplit or any voice bridge.

## 3. Connect Roblox Studio to Codex (20–30 minutes)

1. Install or update Roblox Studio and sign in as `jwallyguy` or `Awchism`.
2. Confirm that account has Edit access to the private `Pipilabu` experience.
3. In Studio, open **Assistant → … → Manage MCP Servers** and enable Studio as an MCP server.
4. In Codex, ask it to configure the Studio MCP command for Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
5. Make Codex list the open Studio instances and prove it selected exactly:
   - PlaceId `133099029551440`
   - GameId / UniverseId `10646495069`
6. Never let it mutate the older duplicate PlaceId `104936800417970`.

## 4. Prepare the code bridge, but do not invent the source (15 minutes)

Codex may install Git, Rokit, Rojo, Lune, Wally, and the Rojo Studio plugin now. The pinned project versions are Rojo `7.6.1`, Rokit `1.2.0`, Lune `0.10.4`, and Wally `0.3.2`.

Leo's current `v0.9.9-dev` working tree is materially ahead of the last commit and there is no Git remote yet. Wait for Leo's verified private remote or transfer bundle. A clone of the current HEAD alone is incomplete, and an empty replacement repo would be wrong.

Once the real checkout arrives, have Codex:

1. Read `AGENTS.md`, `README.md`, `docs/codex/HANDOFF.md`, `docs/codex/PLAYTEST_QUEUE.md`, and `docs/IDEA_LEDGER.md`.
2. Install the repo-owned `boot-jon-leo-roblox` skill.
3. Start exactly one Rojo server on `localhost:34872`.
4. Connect the Rojo Studio plugin and verify disk and Studio both report the same development version.
5. Build with Rojo and report any Studio Output errors before changing gameplay.

## 5. Your first successful Codex session

Ask Codex for a setup report containing the local repo path, branch/HEAD/remote, tool versions, Rojo listener, connected Studio IDs, live development version, Output errors, and current playtest status. Then give it one bounded job, such as inspecting the current playtest queue or diagnosing one Studio error. Let it finish and verify that job before starting another.

## Tips for working one thing at a time

- One task is enough. Keep using the same Pipi Labu task until setup is complete.
- State the outcome and boundary, not every click: “Get Studio connected and prove the PlaceId; do not publish anything.”
- Ask Codex to **do** the inspection, installation, editing, and verification—not merely explain commands for you to run.
- When something fails, paste the exact error or let Codex inspect the screen/terminal. Do not paraphrase it from memory.
- End each checkpoint with: “What did you verify, what remains, and what is the single next action?”
- Do not approve publishing, public release, paid assets, destructive changes, or a new remote unless Leo and you explicitly decide to do that.

## Not part of Jon's setup

The repo contains an older Leo/XSplit voice-bridge experiment. It is currently optional and unverified for Leo's QuadCast. Jon does not need it, and Codex should leave it off.
