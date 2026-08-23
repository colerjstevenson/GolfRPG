# Golf RPG — Build Plan

## 1. Project Goal

Build a small, playable web game that feels like a short golf round with embedded civic-survey moments. The actual primary value is not realistic golf simulation — it is the loop of:

Hit ball → walk → talk → answer → see the course change → continue.

The project should stay intentionally small at first. The first milestone is one hole, one NPC, one question, and one visible transformation. Once that loop works, the project can expand to nine holes.

---

## 2. Recommended Development Strategy

Use a staged build, not a full “all-at-once” production pass.

### Phase 1 — Lock the vision and scope
- Decide the exact player fantasy.
- Define the survey themes and tone.
- Choose the technology stack and prototype target.
- Set the first playable milestone.

### Phase 2 — Build the playable prototype
- One hole
- One golf mechanic loop
- One NPC encounter
- One survey question
- One transformation effect

### Phase 3 — Expand to full game structure
- Nine-hole progression
- Randomized question bank
- Course value tracking
- Layered transformation system
- Final course summary screen

### Phase 4 — Polish and research-readiness
- Improve pacing
- Add more NPC variety
- Tune content and answer impact
- Review data collection needs

---

## 3. Work You Should Prep on Your Own

These are the parts that are easiest to get wrong if left to a tool, because they require your judgment, research goals, and creative direction.

### 3.1 Clarify the core concept
You should define:
- What the game is trying to say
- The central theme: public use of golf-course land
- The intended emotional tone
- How "fun" the game should feel versus how "research-driven" it should feel

This is not something to hand off to AI because it shapes every later decision.

### 3.2 Decide the research questions and survey content
You should decide:
- Which ideas matter most
- Which categories should be tracked
- What is a meaningful answer set
- What data should be collected and what should be avoided
- Whether the project is educational, exploratory, or explicitly research-oriented

AI can help generate a large question bank, but you should curate the final categories and wording.

### 3.3 Define the visual identity
You should decide:
- Art style
- Color palette
- Tone of the environment
- How the course changes from sterile to community-oriented
- How much of the transformation is subtle versus obvious

This work requires a strong design direction and should not be left entirely to a generator.

### 3.4 Set the gameplay rules
You should define:
- How shots work
- Whether the player hits toward a target or a hole
- How many strokes are allowed per hole
- What counts as “complete” for a hole
- How walking and exploring are structured

Even a simple golf loop needs a clear rule set before code starts.

### 3.5 Determine project constraints
You should decide:
- Scope for the prototype
- Realistic time budget
- Whether this is a single-person build or collaborative
- Budget for art and audio
- Whether web export is required from day one

This is the planning layer that prevents the project from growing beyond reason.

### 3.6 Create the final editorial voice
You should write the tone for:
- NPC dialogue
- Survey prompts
- Course summary text
- End-of-game framing

A good AI-generated draft will still need human editing to sound believable and consistent.

### 3.7 Decide what data is ethically acceptable
If any research data is collected, you must decide:
- What is required
- What is optional
- How responses are anonymized
- Whether explicit consent is required
- What privacy language must appear in the game or surrounding materials

This is a non-negotiable human decision.

---

## 4. Parts That are Great for AI Assistance

These are easy and productive areas to hand to AI if you provide clear constraints.

### 4.1 Question bank generation
AI can produce:
- Large lists of survey questions
- Category tags
- Varied wording styles
- Response choices with weighted values
- Alternative question formulations for different NPC types

Best use: generate many candidate questions, then select the strongest ones.

### 4.2 NPC dialogue generation
AI can help with:
- Character archetypes
- Short conversational prompts
- Reactions to player choices
- Dialogue variations by tone and personality
- Short, readable lines for a one-minute encounter

Best use: write multiple NPC styles and prune for clarity and pacing.

### 4.3 Data schema and game state structure
AI can help create:
- Question data objects
- Category mapping
- Course value tracking
- Player stats and progression records
- Save data structure for session state

This is ideal for AI because it is structured and mechanical.

### 4.4 Prototype code scaffolding
AI can generate:
- Basic project structure
- State managers
- UI shells
- Dialogue system skeletons
- Event logic for question responses
- Data-driven content loaders

This reduces setup time dramatically, especially for an early prototype.

### 4.5 Simple systems and logic
AI can handle:
- Score value calculations
- Random question selection
- NPC pool selection
- Layer activation rules
- Course transformation thresholds
- Summary generation for final screen

These are perfect examples of rules-heavy logic that are easy to model with prompt-driven code generation.

### 4.6 Placeholder art and asset lists
AI can produce:
- Asset inventories by category
- Simple sprite naming conventions
- Layer planning documents
- Placeholders for grass, benches, paths, and signage
- Production-ready task lists for future art work

This helps keep design organized even before final art is created.

### 4.7 Testing and validation support
AI can generate:
- Unit tests for logic
- Playtest checklists
- Debugging scripts
- Validation of question balance
- Smoke-test flows for a full round

This is especially useful for making sure the prototype remains playable.

### 4.8 Documentation and planning
AI can help draft:
- Game design docs
- Technical notes
- Implementation checklists
- Content management spreadsheets
- Build logs and milestone tracking

AI is especially good at turning rough ideas into clear operational tasks.

---

## 5. Recommended Prototype Scope (First Milestone)

Build a playable first version with these limits:

### Required
- One short golf hole
- Simple movement on a small map
- Basic shot mechanic
- Ball travels to a target area
- One NPC encounter
- One survey question with 3–4 answer choices
- Simple answer tracking
- One noticeable environmental change triggered by the answer

### Not required yet
- Full nine-hole progression
- Large NPC diversity
- Complex golf physics
- Rich art
- Procedural transformation logic beyond a single layer
- Advanced audio or animation

The test of success is not “does it look complete?” It is:

Does the player experience a satisfying loop where their choice changes the world?

---

## 6. Target Build Timeline

A realistic early version could be built in phases like this:

### Week 1 — Direction and setup
- Finalize concept and tone
- Choose engine/platform
- Define rules and win conditions
- Create prototype scope document
- Decide what data is recorded

### Week 2 — Core loop
- Build movement and hole layout
- Implement shot behavior
- Add ball travel and player progress
- Create a basic walk-to-ball loop

### Week 3 — NPC and survey interaction
- Add one NPC trigger
- Implement question UI
- Link answer choices to state changes
- Confirm the question is short and readable

### Week 4 — Transformation feedback
- Add environmental change layer
- Show world state before and after answer
- Confirm the player understands cause and effect

### Week 5 — Expansion prep
- Design the nine-hole progression structure
- Create question categories and content lists
- Define transformation thresholds
- Plan future NPC archetypes

### Week 6+ — Full game expansion
- Add more holes
- Add randomized question bank
- Add layered course changes
- Add final summary screen
- Tune pacing and content

---

## 7. Suggested Division of Labor

### Human-owned decisions
- Core artistic direction
- Research framing and survey ethics
- Game tone and interpretation
- What is worth keeping or cutting
- Final balancing and quality review
- Final narrative arcs and structure

### AI-assisted tasks
- Large content generation
- Drafting dialogue and questions
- Boilerplate code creation
- Logic prototypes
- Data modeling
- Script generation and automation
- Rewriting, restructuring, and summarization of design tasks

### Shared tasks
- Review AI-created content
- Remove low-quality or repetitive output
- Fit content into the actual game structure
- Refine systems after playtesting

---

## 8. Best Workflow with AI

Use AI as a force multiplier, not as a replacement for design judgment.

### Good AI prompts should include:
- The exact purpose of the content
- The target tone and audience
- The game’s core constraints
- The content type and length
- The desired categories or tags

### Example AI tasks
- “Generate 30 survey questions about public access and community use for a friendly, conversational tone.”
- “Draft 10 NPC archetypes with 3 short questions each for a casual golf course setting.”
- “Create a simple GDScript structure for survey state, player stats, and course value tracking.”
- “Write a one-hole prototype checklist for a Godot-based 2D web game.”

### Then review the output with these questions:
- Does this fit the mood?
- Is it too long or too mechanical?
- Does it conflict with the project goals?
- Is it easy to turn into a game system?
- Is it aligned with the research intention?

---

## 9. Risk Areas to Watch

These are the main ways the project can drift off scope:

- Building too much golf simulation before the survey loop is solid
- Over-creating unique assets instead of reusing modular layers
- Writing too many questions without testing their impact
- Making NPC conversations too long
- Turning the game into a disguised survey rather than an experience
- Expanding to nine holes before the one-hole prototype is enjoyable

The cure is simple: keep the first milestone narrow and intentional.

---

## 10. Final Recommendation

Start by building the smallest version that proves the concept:

One hole + one NPC + one question + one visible transformation.

That will answer the most important question:

Does the loop feel like a game, and does the player’s choice meaningfully change the world?

If that works, everything else — nine holes, more NPCs, richer survey content, and course transformation layers — becomes a straightforward expansion problem rather than a conceptual risk.

---

## 11. Immediate Next Step

Before coding, create three small planning artifacts:

1. A one-page game brief
2. A survey question bank with categories
3. A prototype checklist for the first playable hole

Once these exist, the project is ready for implementation, and AI can help generate much of the content and scaffolding while you keep the design direction and final judgment intact.
