# Golf RPG — Project Overview

## 1. Project Concept

**Golf RPG** is a small 2D web-based game that combines a casual round of golf with an interactive survey about the use, purpose, and accessibility of golf-course land.

The player plays a nine-hole round of golf while walking around a golf course. Between shots, the player encounters NPCs who engage them in short conversations and ask questions related to golf courses and how people use or perceive them.

The player's answers influence how the golf course evolves throughout the game.

The game begins as a relatively sterile, corporate-feeling golf course. As the player progresses through the nine holes and answers survey questions, the course gradually becomes more vibrant and community-oriented, reflecting the player's responses.

The ultimate goal is to create an experience that is:

* A simple, enjoyable golf game
* An RPG-like exploration experience
* An interactive survey
* A visual demonstration of different possible uses for golf-course land
* A source of useful survey/research data

The game should remain small in scope and prioritize the interaction and research concept over sophisticated golf simulation.

---

# 2. Core Player Experience

The primary gameplay loop is:

**Hit ball → Walk to ball → Explore → Talk to NPCs → Answer questions → Hit again → Complete hole → Course evolves**

The player should feel like they are actually moving through a golf course during a round rather than simply completing a series of survey screens.

Walking between shots provides the primary opportunity for exploration and NPC interaction.

The survey should therefore feel integrated into the game world rather than being presented as a traditional questionnaire.

---

# 3. Nine-Hole Structure

The game consists of exactly **nine holes**.

The nine holes should provide a clear progression through the experience.

### Holes 1–3: Introduction

The player learns:

* Basic movement
* Basic golf mechanics
* How to interact with NPCs
* How the question system works

Survey topics can establish the player's relationship with golf and golf courses.

The course remains mostly in its initial corporate/sterile state.

### Holes 4–6: Transformation

Questions increasingly focus on:

* Who should be able to use golf-course land
* Non-golf uses
* Public access
* Recreation
* Environmental considerations
* Community use

The player begins noticing meaningful changes to the course.

### Holes 7–9: Community Course

The transformation becomes increasingly obvious.

The player encounters a course that is no longer exclusively focused on golf.

Depending on their answers, it may contain:

* Walking trails
* Community gardens
* Wildlife habitat
* Picnic areas
* Family recreation
* Community gathering areas
* Outdoor events
* Other forms of public recreation

The final hole should feel like the culmination of the player's decisions.

---

# 4. Golf Mechanics

Golf should be intentionally simple.

This is **not intended to be a golf simulator**.

The basic mechanic should be:

1. Player approaches ball.
2. Player enters shot mode.
3. Player aims.
4. Player chooses shot power.
5. Player hits the ball.
6. Ball travels to a new location.
7. Player walks to the ball.
8. Player can encounter NPCs and explore while walking.
9. Repeat until the hole is completed.

The golf mechanics should be easy to understand and quick to play.

The walking/exploration and survey systems are more important to the project's identity than realistic golf physics.

---

# 5. NPC System

NPCs are the primary interface between the player and the survey.

Rather than presenting the player with a conventional questionnaire after every hole, NPCs should ask questions naturally during the round.

Example:

> "I don't really golf. I mostly come here to walk. Do you think courses should have more spaces for people who don't golf?"

The player then selects from several responses.

Possible NPC types include:

* Golfers
* Walkers
* Local residents
* Parents
* Retired people
* Course employees
* Environmental/community volunteers
* Other recreational users

NPCs should represent different perspectives surrounding golf courses.

NPC conversations should be short enough that they don't interrupt the flow of the round.

---

# 6. Survey System

Survey questions should be selected from a larger question bank.

Questions should be randomized so that players do not necessarily encounter the exact same sequence every time.

However, the system should maintain enough structure to ensure that important research categories are represented.

Questions may address topics such as:

* Frequency of golfing
* Importance of golf as a recreational activity
* Public access to golf-course land
* Walking and trails
* Environmental value
* Wildlife habitat
* Community recreation
* Family activities
* Events and social spaces
* Accessibility
* Alternative uses of golf-course land
* Perceptions of golf courses
* The relationship between golf and surrounding communities

Survey questions should be stored as data rather than hard-coded into individual NPCs.

---

# 7. Course Transformation

Each hole begins in a private course state with its private item layer visible, a muted HUD overlay, and no active wildlife. A hole qualifies for transformation when the player has answered every question offered by its NPCs during the current round.

After the player completes a qualifying hole and chooses its exit, the player pauses before leaving while the camera flies out to show the course. The hole changes to its community state during that view: its community item layer appears, rough detail is added, ducks become active, and the private overlay becomes lighter based on the number of transformed holes.

Survey answers remain in the response log across rounds. An incomplete round still starts again in the private state because only answers made in the active round qualify transformations. Transforming all nine holes permanently unlocks the community course state for future restarts and application launches.

---





# 10. Asset Strategy

Asset scope must remain intentionally small.

The game should use a reusable library of modular assets rather than unique assets for every hole.

Potential reusable asset categories:

### Golf

* Fairway
* Rough
* Green
* Bunkers
* Flags
* Golf balls
* Golf carts
* Clubs
* Golfers

### Environment

* Trees
* Bushes
* Flowers
* Grass
* Water
* Rocks
* Fences
* Paths

### Community

* Benches
* Picnic tables
* Gardens
* Small playground elements
* Community signs
* Gathering spaces

### Recreation

* Walking paths
* Exercise equipment
* Open recreation areas
* Other simple recreational objects

### Social

* Market stalls
* Small stage
* Tables
* Event decorations
* Groups of people

The same assets should be reused across multiple holes whenever possible.

---

# 11. Data Collection

The game should be designed so that survey responses can potentially be collected as research data.

Possible data points include:

### Survey Data

* Question presented
* Answer selected
* Question category
* Time taken to answer
* Order in which questions were presented

### Gameplay Data

* Hole completed
* Number of shots
* Time spent on each hole
* NPCs encountered
* NPC interactions
* Course features generated
* Final course characteristics

### Optional Demographic/Research Data

If required by the research project, the game may collect additional information such as:

* Golf participation
* Age range
* General location
* Other relevant demographic information

Any collection of personal or research data should be implemented according to the requirements of the research project and its applicable consent/privacy process.

---

# 12. Final Player Experience

After completing the ninth hole, the player should be shown the course they created.

Rather than simply displaying survey statistics, the game should visually communicate the result.

For example:

> ## Your Community Course
>
> You completed 9 holes and spoke with 15 people.
>
> Your course became:
>
> * Nature-focused
> * Walking-friendly
> * Family-oriented
> * Community-focused
> * Still strongly focused on golf
>
> Your course now includes:
>
> * Public walking trails
> * Wildlife habitat
> * Community gardens
> * Picnic areas
> * Community gathering spaces
> * An 18-hole golf course

The final screen can optionally provide additional information about the player's survey responses.

---

# 13. Design Principles

The following principles should guide development.

### 1. Survey first, game second

The golf mechanics exist to create an engaging context for the survey.

The project should not become a full golf simulator.

### 2. The player should feel like they are playing a game

Avoid making the experience feel like a disguised web questionnaire.

### 3. Answers should have consequences

Whenever practical, player choices should be reflected somewhere in the game.

### 4. Keep the transformation system simple

Use reusable assets and broad environmental categories instead of attempting fully procedural course generation.

### 5. Reuse assets aggressively

A small number of well-designed assets should be used throughout all nine holes.

### 6. Keep interactions short

NPC conversations should generally take seconds rather than minutes.

### 7. The world should tell the story

Whenever possible, show the consequences of survey responses visually rather than explaining them through text.

### 8. Nine holes is the complete experience

The project should aim for a polished, relatively short experience rather than expanding into a large golf RPG.

---


# 15. Technology Direction

The intended platform is the **web**.

Godot is a strong candidate for implementation because the project primarily requires:

* 2D movement
* Tile-based environments
* Simple physics
* NPCs
* Dialogue
* UI
* Data-driven questions
* State management
* Web export

The implementation should prioritize a lightweight 2D architecture suitable for browser deployment.

Specific technical architecture should remain flexible during early prototyping.

---

