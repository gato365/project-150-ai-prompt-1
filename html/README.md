# AI Prompting Experiment — STAT 252, Spring 2026
**Cal Poly SLO · Dr. Immanuel Williams · IRB Protocol #2026-053**

---

## What This Repo Contains

```
ai-experiment/
├── html/
│   └── experiment.html       ← Single HTML file: guide + activity (all groups)
├── data/
│   ├── group_assignments.csv ← Generated after pretest (4/27); codes → groups
│   └── [post-experiment]     ← Canvas exports, MS Forms download (added later)
├── scripts/
│   └── assign_groups.R       ← Reads pretest scores, assigns codes, emails students
└── README.md                 ← This file
```

---

## Overview

This experiment investigates how different **AI prompting techniques** affect student learning of a new statistical concept — **within-group and between-group variability in one-way ANOVA**.

Students are randomly assigned to one of **three conditions**:

| Group | Code Prefix | Description |
|---|---|---|
| **Control** | `1xxx` | No AI. Use provided notes only. |
| **No Structure** | `2xxx` | Use CSU ChatGPT freely — no format required. |
| **Structure (RTF)** | `3xxx` | Use CSU ChatGPT with Role-Task-Format prompting. |

---

## Experiment Timeline

### 4/27 — Previous Class (last 10 minutes)
- Students complete **Pre-Test** on Canvas (closes at end of class)
- Send reminder email: set up CSU ChatGPT account before 4/29

### Between 4/27 and 4/29
- Run `assign_groups.R`: pull Canvas pretest scores, balance groups, assign 4-digit codes
- Email each student their code (or post privately via Canvas)
- Populate the `GROUP_LOOKUP` object in `experiment.html` with the final code→group mapping

### 4/29 — Experiment Day (class period)

```
┌─────────────────────────────────────────────────────┐
│ Step 1 │ Instructor teaches One-Way ANOVA example   │  ~15 min
│        │ PSO, TOV, RV/EV setup                      │
├─────────────────────────────────────────────────────┤
│ Step 2 │ Students sign paper consent forms          │  ~3 min
├─────────────────────────────────────────────────────┤
│ Step 3 │ Students open experiment.html              │  ~25 min
│        │ Enter code → see group → read guide →      │
│        │ complete activity (4 questions)             │
│        │                                            │
│        │  Control:     use reference notes          │
│        │  No Structure: free AI prompting           │
│        │  Structure:   RTF prompting template       │
├─────────────────────────────────────────────────────┤
│ Step 4 │ Post-Test on Canvas                        │  ~8 min
├─────────────────────────────────────────────────────┤
│ Step 5 │ Treatment students submit chat via         │  ~4 min
│        │ Microsoft Forms (using their code)         │
├─────────────────────────────────────────────────────┤
│ Step 6 │ Instructor debrief                         │  ~10 min
│        │ - Show all 3 techniques side by side       │
│        │ - Formally teach BTW/Within, F-ratio       │
│        │ - Discuss quality of information + AI      │
└─────────────────────────────────────────────────────┘
```

---

## The HTML: How It Works

`experiment.html` is a **single self-contained file** with no external dependencies (except Google Fonts). It handles all three groups in one URL.

### What students see (flow):

1. **Code entry screen** — student enters 4-digit code
2. **Group reveal + guide** — based on their group:
   - Control → reference notes, no AI instructions
   - No Structure → open AI exploration prompt
   - Structure → RTF template with fill-in-the-blank guidance
3. **Activity** — same 4 questions for all groups; what differs is the tool
4. **Prompt submission guide** — how to copy & paste from ChatGPT into MS Forms
5. **Completion screen**

### Before deploying:
Edit the `GROUP_LOOKUP` object near the bottom of the `<script>` block:

```javascript
const GROUP_LOOKUP = {
  "1001": "control",
  "2001": "nostructure",
  "3001": "structure",
  // ... add all assigned codes
};
```

**The HTML file can be hosted on:**
- GitHub Pages (recommended — free, instant)
- Any static file host
- Uploaded directly to Canvas as an HTML file

---

## The Three Groups — Detailed

### Control Group (`1xxx`)
- Receives: reference notes embedded in the HTML
- Does not use AI, Google, or any external resource
- Activity: read notes → answer 4 questions
- No prompt to submit to MS Forms

### No Structure (`2xxx`)
- Receives: the learning objective phrase only:
  *"Learn between-group and within-group variability in the context of one-way ANOVA"*
- Uses CSU ChatGPT however they want — no format required
- May ask any number of follow-up questions
- Submits full conversation to MS Forms

### Structure — RTF (`3xxx`)
- Receives: RTF (Role, Task, Format) template with fill-in-the-blank prompts
- Required to use RTF structure on Prompt 1, and encouraged on follow-ups
- Submits full conversation to MS Forms

---

## Data Collection

| Source | What It Contains | Linked By |
|---|---|---|
| Canvas Pre-Test | Prior knowledge scores | Student name/email |
| Canvas Post-Test | Post-activity scores | Student name/email |
| MS Forms | ChatGPT conversation text | Participant code |
| `group_assignments.csv` | Code → group → Canvas ID | Participant code |
| Consent forms | Signed paper forms | Stored in Dr. Williams's office |

### Linking records:
The 4-digit participant code is the **bridge**:
- Student enters it in the HTML → determines their group
- Student enters it in MS Forms → links their chat to their data
- `group_assignments.csv` maps code → Canvas student ID
- Canvas pre/post → matched by Canvas student ID

---

## Learning Objectives Assessed (Post-Test)

The post-test questions target:

1. Define within-group variability in your own words
2. Define between-group variability in your own words
3. Interpret the F-ratio — what does F >> 1 mean? F ≈ 1?
4. Explain why equal within-group variance is required for ANOVA

---

## Open Items Before 4/29

- [ ] Run `assign_groups.R` after pretest closes on 4/27
- [ ] Populate `GROUP_LOOKUP` in `experiment.html`
- [ ] Email/post participant codes to students
- [ ] Confirm MS Forms URL is live and accessible
- [ ] Post Post-Test quiz in Canvas and confirm timing
- [ ] Print consent forms
- [ ] Test HTML on a phone + laptop before class

---

## Research Questions (IRB #2026-053)

1. Do students who use AI (either condition) show greater pre→post learning gains than the control group?
2. Does structured prompting (RTF) produce different learning outcomes than unstructured AI use?
3. What patterns emerge in student prompts across conditions — in terms of quality, depth, and technique adherence?

Analysis plan: Sam's Shiny app at `samottobiz.shinyapps.io/ai-research-spring-2026-sjo/`
