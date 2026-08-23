# Golf RPG - Phase 2 Prototype Plan

## 1. Purpose of This Prototype

Phase 2 is about proving the smallest playable version of the Golf RPG concept.

The goal is not to build the full nine-hole game yet. The goal is to confirm that the core loop feels understandable, playable, and meaningful:

```text
Hit ball -> walk to ball -> meet NPC -> answer question -> see course change -> finish hole
```

The prototype should answer one question:

Does the player feel that their choice inside the survey meaningfully changes the game world?

If the answer is yes, the project is ready to expand. If the answer is no, the project needs design adjustment before adding more holes, questions, NPCs, or art.

---

## 2. Prototype Scope

### Must include

- One short 2D golf hole
- A player character who can walk around the course
- A ball that can be hit toward a target or hole
- A simple shot mechanic with aim and power
- A basic stroke counter
- One NPC encounter placed between the tee and the hole
- One survey-style question randomly pulled from `data/questions.json`
- 3-4 answer choices loaded from that question data
- Game state that records the selected answer
- One visible environmental transformation caused by the answer
- A simple end state when the hole is completed

### Should include if time allows

- A short title/start screen
- A basic completion screen
- Placeholder sound effects for hit, dialogue, and transformation
- A simple debug display for stroke count, selected question, and selected option
- A reset/replay option

### Should not include yet

- Nine-hole progression
- Weighted or category-based question selection
- Multiple NPCs
- Complex golf physics
- Full save/load support
- Research data export
- Final art polish
- Complex branching dialogue
- Multiple transformation layers
- Online leaderboards, accounts, or analytics

The prototype should stay small enough that every feature directly supports the core loop.

---

## 3. Recommended Technical Target

The larger plan calls for a small playable web game. For Phase 2, choose the simplest stack that can produce a browser-playable prototype quickly.

### Good options

- **Godot 2D exported to web**: Best if you want a real game engine, scene editor, collisions, and future expansion.
- **HTML5 Canvas / JavaScript**: Best if you want a lightweight browser prototype with minimal setup.
- **Phaser**: Best if you want a web-native 2D game framework with sprite, input, and physics helpers.

### Decision

Use **Godot 2D**, exported for the web. This supports top-down movement, collisions, scenes, dialogue UI, and future nine-hole expansion without requiring realistic golf simulation.

### AI assistance

The prototype should use a top-down camera. AI can scaffold the Godot project and browser export workflow after the one-hole layout and temporary content are specified.

---

## 4. Core Design Decisions You Should Make Manually First

These choices should be made by you before asking AI to generate code or content. They define the taste, meaning, and constraints of the prototype.

### 4.1 Player fantasy

**Chosen direction:** A playful golf RPG character discovering broader community use of the course.

Decide what the player is meant to feel like:

- A golfer discovering broader community use of the course
- A visitor exploring a golf course as public land
- A local resident participating in a civic conversation
- A playful RPG character moving through a lightly satirical golf world

### 4.2 Prototype tone

**Chosen direction:** Cozy and community-focused.

Decide whether the prototype should feel:

- Friendly and curious
- Lightly critical
- Civic and educational
- Cozy and community-focused
- Strange, funny, or surreal

### 4.3 Shot input

Use an **aim plus hold/release power** shot. The player aims, holds the shot button to charge power, and releases to hit the ball.

### 4.4 Question bank content

For now, do not worry about survey themes, categories, scoring, or weighting. The prototype only needs a JSON file with a list of questions and options.

Each question should include:

- A stable question ID
- A short prompt
- 3-4 answer options
- A stable option ID for each answer

The game should randomly choose one question when the NPC interaction begins.

### 4.5 NPC and transformation content

The specific NPC identity and transformation theme are intentionally deferred for this initial prototype. Use replaceable placeholder content so implementation can begin without locking the creative direction.

The prototype must still include one NPC interaction and one visible transformation trigger. The temporary transformation only needs to prove that answering changes the world; it can later be replaced with the final community-use idea.

### 4.6 The one visible transformation

Choose exactly one environmental change for the prototype. Examples:

- A locked cart path becomes a public walking path
- Empty rough becomes a small community garden
- Sterile grass gains wildflowers and habitat signs
- A fenced-off area becomes a picnic space
- A corporate sign changes into a community notice board

### 4.7 What the prototype records

Decide whether the prototype only records state locally during play or whether it should prepare for future research data collection.

For Phase 2, the safest default is local-only state:

- Selected answer
- Selected question ID
- Selected option ID
- Stroke count
- Whether the transformation has triggered

Avoid collecting personal information in the prototype unless you have already made the ethics and privacy decisions.

---

## 5. AI vs Manual Responsibility Summary

| Area | AI can handle | You should handle manually |
| --- | --- | --- |
| Engine setup | Scaffold files, install dependencies, create starter scenes | Choose the stack and confirm workflow |
| Golf mechanic | Draft aiming, power, ball movement, collision logic | Decide how simple or skill-based shots should feel |
| Movement | Implement walking controls and interaction triggers | Judge whether movement feels good enough |
| NPC dialogue | Draft short lines and answer options | Final wording, tone, and research meaning |
| Survey data | Create `data/questions.json`, random question loading, selected answer state | Write or approve question wording and options |
| Transformation | Implement layer toggles or sprite swaps | Choose what the visual change means |
| Art placeholders | Generate asset lists, simple shapes, placeholder sprites | Approve visual direction and replace weak placeholders |
| Testing | Create smoke tests and playtest checklist | Play the prototype and judge whether the loop works |
| Documentation | Draft setup notes and feature checklist | Decide what belongs in the real roadmap |

---

## 6. Prototype Build Stages

### Stage 1 - Lock the prototype brief

The prototype brief is now locked for implementation, with NPC identity and transformation theme left as replaceable placeholder content.

The brief should include:

- Engine or framework choice: Godot 2D exported to web
- Target platform: web browser
- Camera style: top-down
- Shot input style: aim plus hold/release power
- One-hole layout description
- One NPC concept: temporary placeholder; identity deferred
- Question bank format
- One transformation effect: temporary placeholder; theme deferred
- Definition of complete: sink the ball, talk to every NPC on the hole, then exit through the trail near the end of the hole

AI can help by turning your rough answers into a clean brief.

You should manually approve the brief before implementation starts.

### Stage 2 - Create the project scaffold

Build the minimal runnable project.

AI can handle:

- Creating the folder structure
- Adding starter source files
- Setting up a development server or export workflow
- Creating placeholder scenes or canvas layers
- Adding a README with run instructions

You should handle:

- Confirming the project runs on your machine
- Confirming the chosen stack feels comfortable
- Deciding whether the setup is too heavy for the prototype

Done when:

- The game opens in a browser or engine preview
- A blank or placeholder course screen appears
- The project has clear run instructions

### Stage 3 - Build player movement

Implement a player character who can move around the course.

AI can handle:

- Keyboard movement
- Basic collision boundaries
- Camera follow behavior
- Interaction radius logic
- Simple player placeholder art

You should handle:

- Testing whether movement speed feels right
- Deciding whether the camera framing supports exploration
- Checking whether the player can easily find the ball and NPC

Done when:

- The player can walk around the hole
- Movement is readable and controllable
- The player cannot accidentally leave the playable area

### Stage 4 - Build the one-hole golf loop

Implement the minimum golf mechanic.

AI can handle:

- Ball object or entity
- Shot mode near the ball
- Aim direction indicator
- Power meter or fixed power levels
- Ball movement after the shot
- Stroke counter
- Hole/target detection

You should handle:

- Tuning how much skill the shot requires
- Playtesting whether the ball travel feels satisfying
- Deciding the expected number of strokes for the prototype hole

Done when:

- The player can approach the ball
- The player can aim and hit it
- The ball travels to a new position
- Stroke count increases
- The player can walk to the ball and hit again
- The hole can be completed

### Stage 5 - Add the NPC encounter

Place one NPC in the walking path between the tee and the hole.

AI can handle:

- NPC interaction trigger
- Dialogue box UI
- Short dialogue sequence
- Answer choice buttons
- Basic input handling for selecting an answer

You should handle:

- Replacing the temporary NPC identity when the creative direction is ready
- Editing the dialogue so it sounds natural
- Making sure the question does not feel like a disconnected survey pop-up
- Deciding whether the player must answer or can walk away

Done when:

- The player can approach the NPC
- A short conversation appears
- The player can choose one answer
- The answer is stored in game state
- The conversation closes cleanly

### Stage 6 - Load a random survey question

Create the smallest useful data model for randomly selecting a question from `data/questions.json`.

AI can handle:

- JSON question bank structure
- Loading questions from `data/questions.json`
- Randomly selecting one question
- Rendering that question's options in the dialogue UI
- Storing the selected question ID and option ID
- Debug display for selected question/option

You should handle:

- Writing or approving the question prompts
- Writing or approving the answer options
- Making sure the options are readable and not manipulative
- Deciding later whether categories, scoring, or weighting are needed

Example prototype data shape:

```json
{
	"questions": [
		{
			"id": "q_001",
			"prompt": "Do you think golf courses should make room for people who do not play golf?",
			"options": [
				{ "id": "strong_yes", "label": "Yes, they should welcome more people." },
				{ "id": "somewhat_yes", "label": "Somewhat, as long as golf still works well." },
				{ "id": "unsure", "label": "I'm not sure yet." },
				{ "id": "no", "label": "No, they should mainly stay for golfers." }
			]
		}
	]
}
```

Done when:

- The NPC interaction pulls one random question from the JSON file
- The dialogue UI shows that question and its options
- The selected question ID and option ID are stored
- The structure is easy to extend with more questions later

### Stage 7 - Add the environmental transformation

Trigger one visible change after the player answers the NPC question. For now, the transformation can happen after any answer is selected; it does not need categories or scoring yet.

AI can handle:

- Showing/hiding a visual layer
- Swapping sprites or tile layers
- Playing a small animation or fade
- Updating signs, props, or path access
- Connecting the transformation to the answered state

You should handle:

- Replacing the temporary visual with the chosen transformation meaning later
- Deciding later whether different answers should trigger different versions
- Checking whether the player notices the change without being over-explained
- Replacing placeholders if the visual idea is unclear

Recommended prototype approach:

- Start with one locked or sterile area.
- After the answer, reveal one new community-oriented element.
- Make the change visible near the NPC or along the route to the hole.

Done when:

- Answering the question causes a visible world change
- The change is noticeable without requiring scoring or categories
- The player can keep playing after the transformation

### Stage 8 - Add completion and replay flow

Finish the prototype with a simple ending. A hole is complete only when the ball is in the cup, every NPC on that hole has been interacted with, and the player reaches the exit trail near the end of the hole.

AI can handle:

- Hole completion detection
- Completion screen
- Stroke count summary
- Selected answer summary
- Restart button

You should handle:

- Writing the final summary tone
- Deciding whether the answer should be shown explicitly
- Judging whether the ending feels like a prototype of the larger idea

Done when:

- The player can sink the ball
- The player cannot exit until all NPC interactions on the hole are complete
- The player can reach the exit trail and advance to the completion screen
- The game shows a simple result screen
- The player can restart without refreshing manually


---

## 7. Temporary Prototype Content

These are implementation placeholders only. Replace them after the core loop works.

### Hole concept

The player starts at a tee on a quiet, polished course. The route to the hole passes a fenced cart path and a lone walker standing near a sign that says "Members Only Path." After the player answers the NPC's question, the path becomes a public walking trail with flowers, benches, and a community notice sign.

### NPC placeholder

Use one temporary NPC placed between the tee and the cup. The identity, role, and dialogue are intentionally undecided.

### Dialogue placeholder

Use one short conversational lead-in followed by a randomly selected question from `data/questions.json`.

### Answer choices

Render the four options from the selected question in `data/questions.json`.

### Transformation placeholder

If the player gives any answer, activate one temporary visual change. The exact environmental meaning is deferred; different outcomes can wait until the full structure exists.

---

## 8. Minimum Data Model

The prototype only needs enough state to support one loop.

```text
GameState
|-- currentHole
|-- strokes
|-- ballPosition
|-- playerPosition
|-- npcInteractionComplete
|-- selectedQuestionId
|-- selectedOptionId
|-- transformationActive
`-- exitUnlocked
```

### AI can handle

- Translating this into code for the chosen engine
- Creating helper functions for loading and selecting questions
- Creating a debug view
- Preparing the structure for future expansion

### You should handle manually

- Reviewing the question wording and options
- Deciding later which values matter long term
- Reviewing whether future research data needs consent language

---

## 9. Placeholder Asset List

Use placeholders until the loop is proven.

### Required placeholders

- Player sprite or shape
- Golf ball sprite or shape
- Tee marker
- Hole/cup marker
- Fairway area
- Rough or boundary area
- NPC sprite
- Dialogue panel
- Answer buttons
- Closed path/fence/sign
- Open path/community feature layer

### AI can handle

- Naming conventions
- Asset folder organization
- Simple temporary shapes or generated placeholder images
- Lists of future final art assets

### You should handle manually

- Final art direction
- Whether the world should look realistic, cozy, satirical, abstract, or map-like
- Which transformation image best communicates the visible change

---

## 10. Testing and Playtest Checklist

### Functional smoke test

- Game starts successfully
- Player can move
- Player can find the ball
- Player can enter shot mode
- Ball moves after being hit
- Stroke count increases
- Player can walk to the new ball position
- Player can talk to the NPC
- Player can select an answer
- Answer is stored
- Course transformation appears
- Player can complete the hole
- Completion screen appears
- Restart works

AI can create automated checks for simple logic, especially state updates and answer-to-transformation rules.

You should manually play the full loop several times because feel, pacing, readability, and emotional effect cannot be judged by automated tests alone.

### Human playtest questions

After playing, answer these manually:

- Did I understand what to do first?
- Did the golf shot feel good enough for a prototype?
- Was walking to the ball clear or annoying?
- Did the NPC feel like part of the world?
- Did the question feel natural?
- Did the transformation feel connected to my answer?
- Did the loop make me curious about a larger nine-hole version?

---

## 11. Suggested AI Prompts for Phase 2

Use prompts like these once you have made the manual decisions.

### Project scaffold

```text
Create a minimal [chosen stack] project for a 2D browser-playable golf RPG prototype. It should include one scene, player movement, a ball object, and placeholder course visuals. Keep the code simple and easy to extend.
```

### Golf mechanic

```text
Implement a simple 2D golf shot mechanic with aim direction, adjustable power, ball movement, stroke count, and a hole target. This is not a realistic golf simulation; it should support a short prototype loop.
```

### NPC and survey

```text
Create a one-NPC dialogue interaction that loads a random question from data/questions.json. Show the selected question prompt and options, store the selected question ID and option ID in game state, and close the dialogue after selection.
```

### Transformation

```text
Connect the survey interaction to a visible course transformation. After any option is chosen, reveal an open walking path layer with simple placeholder visuals.
```

### Playtest checklist

```text
Create a concise playtest checklist for a one-hole golf RPG prototype. It should test movement, shot flow, NPC interaction, answer selection, transformation feedback, and hole completion.
```

---

## 12. Phase 2 Done Criteria

Phase 2 is complete when a player can:

1. Start the prototype.
2. Move around a small golf hole.
3. Hit the ball at least once.
4. Walk to the ball.
5. Talk to one NPC.
6. Answer one question.
7. See the course visibly change.
8. Finish the hole.
9. Understand that their answer affected the world.

The prototype does not need to look finished. It needs to make the core concept playable.

---

## 13. Recommended Next Step

Before writing code, the remaining implementation decisions are:

```text
One-hole layout:
Temporary NPC placement:
Temporary transformation visual:
```

The stack, camera, shot input, player fantasy, tone, question format, and completion rule are decided. The next practical step is to create the Godot project scaffold and build movement inside the one-hole layout.
