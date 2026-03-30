# Personalization: Teaching Your Bot to Learn About You

One of the most powerful patterns we discovered is giving the bot a structured file to record what it learns about you over time. Instead of starting every session as a stranger, the bot reads your profile first and builds on it with every interaction.

This isn't a one-time setup. It's a **learning loop** that compounds over weeks.

---

## How It Works

### 1. The Profile File

Create a structured markdown file in your bot's working directory (e.g., `~/AgentWorkspace/user-profile.md`). See the [template](../examples/personalization/user-profile-template.md) for the full structure.

The file has sections for:
- **Identity** — name, role, timezone, contact info
- **Work style** — how technical they are, communication preferences
- **Scheduling** — buffer times, blackout hours, preferred meeting spots
- **Relationships** — contacts the bot encounters, with context
- **Patterns** — recurring behaviors the bot observes over time

You fill in the basics yourself. The bot fills in the rest.

### 2. The PostToolUse Hook (the learning trigger)

After every Telegram reply, a PostToolUse hook reminds the bot:

```
[STATE REMINDER] You just sent a Telegram reply.
(1) Update ~/AgentWorkspace/bot-state.md if decisions/action items/commitments were made.
(2) If you learned anything new about the user (preference, relationship, habit,
    personal detail), update ~/AgentWorkspace/user-profile.md.
```

This is the key mechanism. The bot doesn't need to "decide" to learn — it gets mechanically prompted after every exchange. Over time, the profile fills in naturally:

- User mentions they prefer 15-minute buffers between meetings? Bot adds it to Scheduling Preferences.
- Bot notices the user always messages on Telegram while traveling? Bot adds it to Recurring Patterns.
- User introduces a new contact in an email? Bot adds them to Relationships & Network.

### 3. The PreCompact Hook (emergency save)

When the context window is about to be compacted, the bot gets an urgent reminder:

```
[PRE-COMPACTION] Context is about to be compacted. IMMEDIATELY:
(1) Save unsaved state to ~/AgentWorkspace/bot-state.md
(2) Update ~/AgentWorkspace/user-profile.md with any new learnings
(3) Add important notes to ~/AgentWorkspace/daily/YYYY-MM-DD.md.
This is your LAST CHANCE to persist context.
```

This catches observations the bot hasn't written down yet. Without it, insights from a long conversation can be lost when the context compacts.

### 4. The PreToolUse Hook (loading at session start)

On the first Telegram reply of a new session, the bot is told:

```
[STARTUP] Read these files FIRST to restore your working memory:
(1) ~/AgentWorkspace/bot-state.md
(2) ~/AgentWorkspace/user-profile.md
(3) ~/AgentWorkspace/daily/YYYY-MM-DD.md
```

The bot reads the profile before its first reply, so it starts every session already knowing your preferences, relationships, and patterns.

---

## The Compounding Effect

This is where it gets interesting. After a few weeks:

- The bot knows your preferred restaurants for lunch meetings
- It knows which contacts are important and how they relate to your work
- It knows you hate sloppy email formatting and adjusts its drafts accordingly
- It knows you travel frequently and adapts its communication style when you're on the road
- It knows your scheduling constraints without being told each time

Each session builds on the last. The profile is the bot's long-term memory — not of conversations, but of **who you are**.

---

## Setup

1. Copy the [user profile template](../examples/personalization/user-profile-template.md) into your bot's working directory
2. Fill in the basics (name, role, timezone, etc.)
3. Add the PostToolUse and PreCompact hooks to your `.claude/settings.local.json` — see the [full hooks example](../examples/hooks/settings.local.json) for the exact config
4. The bot will start learning from the first conversation

---

## Tips

- **Seed it with the basics.** The bot learns faster if you give it a starting point (name, timezone, key preferences). Don't leave it entirely blank.
- **Review it occasionally.** The bot generally gets things right, but check the profile every few weeks to correct any misunderstandings.
- **Keep it concise.** The profile is read at every session start. If it grows too long, prune older or less relevant entries. A few hundred lines is fine; a few thousand is too many.
- **One profile per bot.** If you run multiple bots, each can maintain its own profile focused on its domain (e.g., the work bot tracks scheduling preferences, the engineering bot tracks code style preferences).
