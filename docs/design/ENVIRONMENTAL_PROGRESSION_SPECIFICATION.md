
**Document Type:** Gameplay and Experience Design Specification\
**Status:** Approve
**Version:** 0.1\
**Project:** Pebble Hedz

------------------------------------------------------------------------

## 1. Purpose

This document defines the baseline environmental progression system for
Pebble Hedz.

The environment is not passive decoration.

It is an experiential layer that rewards survival, communicates
distance, creates a sense of journey, and contributes directly to the
emotional rhythm of each run.

The environmental system shall transform progressively as the pebble
travels further through the world.

Every run begins again in daylight.

As the player survives and travels further, the world gradually
progresses through daylight, golden hour, sunset, twilight, moonrise,
and deep night.

The central environmental principle is:

> **Survival reveals beauty. Distance unlocks atmosphere. Every run is a
> new journey of discovery.**

The initial implementation shall establish the complete environmental
journey as a functional baseline.

Final artwork, detailed environmental animation, advanced lighting,
soundscape integration, and visual polish shall follow after the
complete gameplay experience has been established.

------------------------------------------------------------------------

## 2. Experience Intent

The Pebble Hedz environment shall create a world that feels:

-   peaceful
-   beautiful
-   spacious
-   atmospheric
-   alive
-   contemplative
-   quietly stimulating
-   increasingly rewarding to explore

The environment shall provide emotional contrast to the tension of
keeping the pebble alive.

The pebble creates focus, uncertainty, danger, and anticipation.

The environment provides calm, beauty, discovery, and reward.

Together, these systems should create an experiential rhythm of:

> **Focus → Hope → Danger → Relief → Beauty → Surprise**

The player should feel that a successful run is not simply covering
distance.

They should feel that they have travelled through a world.

------------------------------------------------------------------------

## 3. Core Design Principles

### 3.1 Every Run Is a New Journey

Environmental progression resets at the beginning of every new pebble
run.

Every run begins in daylight.

Environmental progression does not persist between runs.

The complete day-to-night journey therefore becomes a reward for
survival within a single exceptional run.

------------------------------------------------------------------------

### 3.2 Distance Drives Discovery

Environmental progression shall be driven primarily by the pebble's
horizontal journey through the world.

The environment shall not depend directly upon:

-   score
-   skip count
-   throw quality
-   butterfly collection
-   lily-pad interaction
-   player input after launch

The environment responds to how far the pebble has travelled.

A normalized environmental progression value shall represent the current
journey state:

``` text
0.0 = beginning of the run
1.0 = deepest currently supported environmental progression
```

------------------------------------------------------------------------

### 3.3 Increasingly Beautiful Visual Moments

Longer survival shall reveal increasingly beautiful environmental
states.

The most visually rewarding version of the world should not necessarily
appear at the beginning of the game.

Players should discover new atmospheric moments by travelling further.

The environmental progression should create subconscious and conscious
curiosity:

> **What will the world look like if I can keep this run alive?**

The environment therefore contributes directly to the game's survival
and replay loop.

------------------------------------------------------------------------

### 3.4 Calm World, Tense Pebble

Environmental movement shall remain restrained.

The world should not compete with the pebble for attention.

Environmental animation should generally favour:

-   slow movement
-   smooth transitions
-   gentle parallax
-   gradual colour change
-   subtle atmospheric motion
-   occasional moments of discovery

The world should remain calm while the pebble creates gameplay tension.

------------------------------------------------------------------------

### 3.5 Stylisation Over Realism

The environment shall use a stylised visual language rather than
photographic realism.

Visual inspiration may be taken from elegant atmospheric games and
interactive experiences, including the principles demonstrated by games
such as Alto's Odyssey, without copying their artwork or visual
identity.

The Pebble Hedz environment should develop its own recognisable visual
language through:

-   simplified forms
-   strong silhouettes
-   layered depth
-   controlled colour
-   atmospheric separation
-   deliberate composition
-   expressive lighting
-   restrained environmental detail

The baseline procedural environment should aim to feel intentionally
authored rather than technically generated.

------------------------------------------------------------------------

## 4. Environmental Journey

Environmental progression shall form one continuous journey.

The following stages define the emotional and visual structure of that
journey.

These stages are design regions rather than discrete runtime states.

Transitions between them shall be continuous.

### 4.1 Morning Calm

The beginning of every run.

The world should feel open, peaceful, and full of possibility.

Characteristics may include:

-   soft daylight
-   spacious sky
-   gentle atmospheric colours
-   distant mountain silhouettes
-   restrained contrast
-   clear visual separation around the pebble and water

The opening environment should already be beautiful while deliberately
leaving room for the world to become richer.

### 4.2 Rich Daylight

As the pebble travels further, the environment gradually develops
additional depth and warmth.

Characteristics may include:

-   increased atmospheric depth
-   more pronounced parallax
-   gradual sun movement
-   subtly richer colour
-   changing water illumination
-   stronger separation between landscape layers

The transition should be subtle enough that the player may not
immediately notice it occurring.

### 4.3 Golden Hour

Golden hour represents the first major environmental reward.

Characteristics may include:

-   warmer directional light
-   deepening landscape silhouettes
-   stronger atmospheric colour
-   long visual gradients
-   warm highlights across the water
-   increased visual richness without increased clutter

The player should feel that they have reached somewhere special.

### 4.4 Sunset

Sunset should become one of the signature environmental moments of
Pebble Hedz.

Characteristics may include:

-   the sun approaching the mountain horizon
-   strong warm sky transitions
-   increasingly silhouetted landscape layers
-   reflected or implied sunlight across the water
-   richer depth and contrast
-   a cinematic but restrained composition

The sunset should emerge gradually from the existing environment rather
than appearing as a triggered spectacle.

### 4.5 Twilight and Moonrise

After sunset, the world transitions through a quieter atmospheric state.

Characteristics may include:

-   fading warm tones
-   deepening blues and purples
-   the gradual appearance of the first stars
-   increased silhouette depth
-   moonrise
-   transition from solar to lunar visual dominance

There should be a meaningful twilight interval between sunset and full
moonlit night.

The moon should feel discovered rather than switched on.

### 4.6 Deep Night

Deep night represents the most advanced baseline environmental reward.

Night shall not simply be a darker version of daytime.

It should become one of the most beautiful states of the world.

Characteristics may include:

-   moonlight
-   reflected moonlight across the water
-   visible stars
-   rich layered silhouettes
-   isolated points of distant warmth
-   subtle signs of life
-   increased atmospheric depth

A player reaching deep night should feel that the run has taken them
somewhere rarely seen.

------------------------------------------------------------------------

## 5. Celestial Progression

The sun and moon shall act as compositional elements within the
environmental journey.

Their movement does not need to represent physically accurate astronomy.

Their purpose is to reinforce:

-   progression
-   time
-   distance
-   atmosphere
-   emotional change

### 5.1 Sun

The sun should gradually move through the sky as the run progresses.

Its journey should contribute to:

-   daylight
-   warming light
-   golden hour
-   sunset

The sun should eventually approach and disappear behind the distant
landscape.

### 5.2 Twilight

The disappearance of the sun shall not immediately cause the moon to
dominate the scene.

A twilight interval should allow:

-   residual warmth to fade
-   the sky to deepen
-   the first stars to emerge
-   the landscape to transition into silhouette

### 5.3 Moon

The moon should rise gradually during later environmental progression.

It should become the dominant visual light source during deep night.

For the baseline, one deliberately designed moon state shall be used.

Changing lunar phases are not required for the baseline.

Future environmental variation may introduce different moon phases
between runs if explicitly designed and approved.

------------------------------------------------------------------------

## 6. Lighting Progression

Lighting shall be treated as a primary environmental storytelling
system.

The environment should not progress solely by changing the sky colour.

Environmental lighting should eventually influence the perceived
relationship between:

-   sky
-   mountains
-   water
-   environmental silhouettes
-   gameplay objects
-   ambient details

The baseline implementation shall establish the visual progression
necessary to prove this principle without requiring final lighting
polish.

The intended progression is approximately:

``` text
Soft Daylight
    ↓
Rich Daylight
    ↓
Warm Directional Light
    ↓
Golden Hour
    ↓
Sunset
    ↓
Twilight
    ↓
Moonrise
    ↓
Moonlit Night
```

All transitions shall remain smooth.

------------------------------------------------------------------------

## 7. Parallax Landscape

The baseline environment shall use multiple landscape layers to create
depth and a sense of travel.

### 7.1 Far Landscape

The farthest mountain layer shall:

-   move very slowly relative to the pebble
-   use the lowest contrast
-   receive the strongest atmospheric treatment
-   create scale and distance

### 7.2 Mid Landscape

The middle landscape layer shall:

-   use moderate parallax
-   provide the primary mountain composition
-   carry stronger shape definition
-   contribute significantly to changing silhouettes

### 7.3 Near Landscape

The nearest environmental landscape layer shall:

-   use the strongest environmental parallax
-   provide framing and foreground depth
-   use stronger silhouettes
-   remain visually subordinate to gameplay

Future elements may include:

-   trees
-   reeds
-   rocks
-   structures
-   vegetation
-   other approved environmental details

These are not required for the initial baseline.

------------------------------------------------------------------------

## 8. Stars

Stars shall emerge progressively during twilight and night.

They shall not appear simultaneously.

The first stars should be sparse and subtle.

Additional stars may become visible as the world darkens.

Star presentation should remain restrained and atmospheric.

Future rare events may include explicitly approved elements such as:

-   shooting stars
-   meteor activity
-   unusual celestial events

These are outside the baseline implementation.

------------------------------------------------------------------------

## 9. Distant Human Warmth

Small distant environmental details may create contrast against the
scale and tranquillity of the landscape.

A distant campfire shall be included in the baseline environmental
journey as a subtle late-run atmospheric discovery.

Its purpose is not gameplay interaction.

It exists as:

-   a small point of warmth
-   evidence of a larger living world
-   visual contrast against deep night
-   an atmospheric discovery for long runs

The campfire should remain distant, subtle, and visually restrained.

------------------------------------------------------------------------

## 10. ASMR and Sensory Design Principles

The environmental system shall support the broader ASMR character of
Pebble Hedz.

Visual ASMR should emerge through:

-   smooth transitions
-   predictable natural motion
-   gradual reveals
-   soft repetition
-   visual rhythm
-   restrained movement
-   atmospheric continuity

The environment should avoid unnecessary visual noise.

Environmental beauty should reward observation without demanding
attention.

The future soundscape will form a separate experiential layer and is
expected to significantly amplify the ASMR qualities of the game.

The environmental system shall therefore be designed so that future
sound progression can align naturally with environmental progression.

Soundscape implementation is explicitly outside the current
environmental baseline.

------------------------------------------------------------------------

## 11. Environmental Progression Model

The environmental system shall maintain a normalized journey progression
value.

Conceptually:

``` text
0.00    Morning Calm
0.20    Rich Daylight
0.40    Golden Hour
0.58    Sunset
0.70    Twilight
0.80    Moonrise
1.00    Deep Night
```

These values are initial design markers only.

They shall not be considered final gameplay tuning values.

Actual progression distances shall be determined through runtime testing
against:

-   achievable run distances
-   player progression
-   visual pacing
-   emotional pacing
-   gameplay tension

The system should support future extension beyond the initial `1.0`
environmental journey if longer gameplay progression requires it.

------------------------------------------------------------------------

## 12. EnvironmentManager Responsibility

The baseline environmental system shall be coordinated by:

``` text
scripts/EnvironmentManager.gd
```

The Environment Manager shall own:

-   environmental journey progression
-   normalization of travelled distance
-   environmental time-of-day progression
-   coordination of baseline environmental presentation
-   sun progression
-   moon progression
-   baseline star progression
-   parallax calculations
-   environmental reset at the beginning of each run

The Environment Manager shall act as a coordinator.

It shall not become an unrestricted container for all future
environmental behaviour.

------------------------------------------------------------------------

## 13. Future Modularisation

Individual environmental responsibilities may become dedicated modules
as the environmental system develops.

Potential future modules may include:

``` text
SkyCycle
CelestialCycle
ParallaxLandscape
StarField
LightingController
DistantEnvironment
WeatherLayer
AmbientWildlife
WaterReflection
```

These are potential future responsibility boundaries only.

They shall not be created prematurely.

A dedicated module should be introduced only when:

-   its responsibility becomes substantial
-   separation improves maintainability
-   separation improves extensibility
-   the existing manager is becoming overloaded
-   the module has a clearly defined ownership boundary

The baseline implementation should remain simple enough to establish the
complete environmental journey while preserving future modularity.

------------------------------------------------------------------------

## 14. Relationship to Existing Gameplay Systems

The environmental system shall not redefine or own:

-   pebble physics
-   launch behaviour
-   normal water simulation
-   jelly-water behaviour
-   lily-pad gameplay
-   butterfly gameplay
-   camera ownership
-   scoring
-   soundscape
-   future wildlife gameplay

Existing validated gameplay systems shall remain protected.

Environmental progression may observe the pebble's travelled distance.

It shall not take ownership of the pebble.

`HookeWater2D.gd` shall remain the authoritative water simulation.

`TestPebbleCharacter.gd` shall remain the authoritative pebble gameplay
system.

Environmental implementation shall not alter these systems merely to
achieve visual effects.

------------------------------------------------------------------------

## 15. Baseline Implementation Strategy

The first environmental implementation shall prioritise proving the
complete experience over final polish.

The baseline should establish:

1.  distance-driven environmental progression
2.  per-run environmental reset
3.  stylised procedural sky presentation
4.  multiple parallax mountain layers
5.  sun progression
6.  sunset transition
7.  twilight transition
8.  moonrise
9.  progressive star appearance
10. deep-night presentation
11. a subtle distant campfire as a late-run atmospheric discovery

Procedural or programmatically drawn visual elements may be used for the
baseline.

These elements should represent the best visual quality reasonably
achievable during the functional baseline phase.

Final art assets may replace procedural presentation later without
redefining the environmental progression architecture.

------------------------------------------------------------------------

## 16. Explicit Non-Responsibilities

The baseline environmental progression system shall not:

-   modify pebble physics
-   modify water physics
-   alter jelly-water gameplay
-   alter lily-pad gameplay
-   alter butterfly gameplay
-   own player input
-   own scoring
-   own launch mechanics
-   own sound playback
-   introduce final production artwork
-   introduce unapproved gameplay mechanics
-   create future modules before they are justified

------------------------------------------------------------------------

## 17. Baseline Acceptance Criteria

The environmental progression baseline shall be considered successful
when:

-   every new run begins in the intended daylight state
-   environmental progression resets correctly between runs
-   progression responds consistently to distance travelled
-   multiple mountain layers create visible depth through parallax
-   the environment transitions smoothly from day toward night
-   the sun visibly participates in the progression
-   sunset is visually recognisable
-   twilight is visually distinct
-   stars emerge progressively
-   the moon rises and becomes visually meaningful
-   deep night remains beautiful and readable
-   a subtle distant campfire is discoverable during the late-run
    environment
-   the water remains the visual anchor of the gameplay scene
-   environmental presentation does not interfere with pebble
    readability
-   no existing validated gameplay system is behaviourally altered
-   the complete environmental journey creates a perceptible sense of
    travel
-   longer survival reveals increasingly rewarding visual moments

The ultimate experiential acceptance criterion is:

> **A player who survives long enough should gradually realise that the
> world around them has transformed and feel that their pebble has
> travelled through a living day into a beautiful night.**

------------------------------------------------------------------------

## 18. Future Experience Layers

Once the baseline environmental journey is proven, future explicitly
approved layers may deepen the experience through:

-   final illustrated environmental assets
-   advanced lighting
-   richer water reflections
-   atmospheric particles
-   weather
-   mist
-   ambient wildlife
-   fireflies
-   rare celestial events
-   environmental variation between runs
-   coordinated soundscape progression
-   additional environmental discoveries

These layers shall build upon the proven environmental progression
foundation rather than replace it.

------------------------------------------------------------------------

## 19. Governing Experience Principle

Pebble Hedz should reward the player not only with greater distance, but
with access to increasingly beautiful moments.

The world itself becomes part of the reason to survive.

> **The pebble creates the tension.**
>
> **The world provides the calm.**
>
> **Survival reveals the beauty.**