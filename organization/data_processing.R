# ============================================================
# data_processing.R
# STAT 252 Spring 2026 — AI Prompting Experiment
# Run this AFTER the experiment (post 4/29)
#
# What it does:
#   1. Reads group_assignments.csv (code → group → canvas_id)
#   2. Reads Canvas pretest + posttest exports
#   3. Reads Microsoft Forms prompt submission export
#   4. Joins everything on participant code / canvas_id
#   5. Computes gain scores
#   6. Removes all PII → writes anonymized analysis dataset
#   7. Writes prompt_data.csv (code + prompts, no names)
# ============================================================

library(tidyverse)
library(janitor)

# ── FILE PATHS ───────────────────────────────────────────────
PATH_ASSIGNMENTS <- here::here("data", "group_assignments.csv")
PATH_PRETEST     <- here::here("data", "canvas_pretest_raw.csv")
PATH_POSTTEST    <- here::here("data", "canvas_posttest_raw.csv")
PATH_MSFORMS     <- here::here("data", "msforms_prompts_raw.csv")
OUTPUT_DIR       <- here::here("data", "clean")

dir.create(OUTPUT_DIR, showWarnings = FALSE)

# ── CANVAS COLUMN CONFIG ─────────────────────────────────────
# Adjust these if your Canvas export has different headers
COL_ID    <- "ID"
COL_EMAIL <- "SIS Login ID"
COL_SCORE <- "Score"
MAX_PRE   <- 10    # pretest max possible score
MAX_POST  <- 10    # posttest max possible score

# ── LOAD GROUP ASSIGNMENTS ───────────────────────────────────
assignments <- read_csv(PATH_ASSIGNMENTS, show_col_types = FALSE) |>
  select(code, group, canvas_id) |>
  mutate(canvas_id = as.character(canvas_id))

cat("Assignments loaded:", nrow(assignments), "students\n")

# ── LOAD CANVAS PRETEST ──────────────────────────────────────
read_canvas <- function(path, score_col_name) {
  read_csv(path, show_col_types = FALSE) |>
    filter(!is.na(.data[[COL_SCORE]]),
           .data[["Student"]] != "Student, Test") |>
    rename(
      canvas_id = all_of(COL_ID),
      !!score_col_name := all_of(COL_SCORE)
    ) |>
    mutate(canvas_id = as.character(canvas_id)) |>
    select(canvas_id, all_of(score_col_name))
}

pretest  <- read_canvas(PATH_PRETEST,  "pre_score")
posttest <- read_canvas(PATH_POSTTEST, "post_score")

cat("Pretest records:", nrow(pretest), "\n")
cat("Posttest records:", nrow(posttest), "\n")

# ── LOAD MS FORMS PROMPT DATA ────────────────────────────────
# Expected columns from MS Forms export:
#   "Participant Code", "Your Conversation" (or similar)
# Adjust column names to match your actual form fields
msforms_raw <- read_csv(PATH_MSFORMS, show_col_types = FALSE) |>
  clean_names()

# Identify the code column and conversation column
# (update these strings to match your actual MS Forms field names)
CODE_COL  <- "participant_code"
CONVO_COL <- "your_conversation"

prompts <- msforms_raw |>
  select(
    code      = all_of(CODE_COL),
    prompt_text = all_of(CONVO_COL)
  ) |>
  mutate(
    code = str_trim(as.character(code)),
    has_prompt = !is.na(prompt_text) & prompt_text != ""
  )

cat("Prompt submissions:", nrow(prompts), "\n")
cat("Non-empty submissions:", sum(prompts$has_prompt), "\n")

# ── JOIN EVERYTHING ──────────────────────────────────────────
analysis_data <- assignments |>
  left_join(pretest,  by = "canvas_id") |>
  left_join(posttest, by = "canvas_id") |>
  left_join(prompts,  by = "code") |>
  mutate(
    pre_pct    = pre_score  / MAX_PRE,
    post_pct   = post_score / MAX_POST,
    gain       = post_score - pre_score,
    gain_pct   = post_pct - pre_pct,
    has_prompt = replace_na(has_prompt, FALSE)
  )

# ── COMPLETION CHECKS ────────────────────────────────────────
cat("\n── Data Completeness ────────────────────────────────────\n")
analysis_data |>
  group_by(group) |>
  summarise(
    n              = n(),
    has_pretest    = sum(!is.na(pre_score)),
    has_posttest   = sum(!is.na(post_score)),
    has_prompt     = sum(has_prompt),
    complete_cases = sum(!is.na(pre_score) & !is.na(post_score))
  ) |>
  print()

cat("\n── Gain Score Summary by Group ──────────────────────────\n")
analysis_data |>
  filter(!is.na(gain)) |>
  group_by(group) |>
  summarise(
    n         = n(),
    mean_pre  = round(mean(pre_score,  na.rm = TRUE), 2),
    mean_post = round(mean(post_score, na.rm = TRUE), 2),
    mean_gain = round(mean(gain,       na.rm = TRUE), 2),
    sd_gain   = round(sd(gain,         na.rm = TRUE), 2)
  ) |>
  print()

# ── WRITE ANONYMIZED OUTPUTS ─────────────────────────────────

# 1. Main analysis dataset — no names, no emails
write_csv(
  analysis_data |>
    select(code, group, pre_score, pre_pct,
           post_score, post_pct, gain, gain_pct, has_prompt),
  file.path(OUTPUT_DIR, "analysis_dataset.csv")
)
cat("\nWrote: data/clean/analysis_dataset.csv\n")

# 2. Prompt data only (treatment groups) — no names
write_csv(
  analysis_data |>
    filter(has_prompt, !is.na(prompt_text)) |>
    select(code, group, prompt_text),
  file.path(OUTPUT_DIR, "prompt_data.csv")
)
cat("Wrote: data/clean/prompt_data.csv\n")

# 3. Summary table
summary_tbl <- analysis_data |>
  filter(!is.na(gain)) |>
  group_by(group) |>
  summarise(
    n         = n(),
    mean_pre  = round(mean(pre_score,  na.rm = TRUE), 2),
    sd_pre    = round(sd(pre_score,    na.rm = TRUE), 2),
    mean_post = round(mean(post_score, na.rm = TRUE), 2),
    sd_post   = round(sd(post_score,   na.rm = TRUE), 2),
    mean_gain = round(mean(gain,       na.rm = TRUE), 2),
    sd_gain   = round(sd(gain,         na.rm = TRUE), 2)
  )

write_csv(summary_tbl, file.path(OUTPUT_DIR, "summary_by_group.csv"))
cat("Wrote: data/clean/summary_by_group.csv\n")

cat("\n── Processing complete. PII has been removed from all output files. ──\n")
cat("Original group_assignments.csv (contains names/emails) stays in /data/ only.\n")
cat("Share only the files in /data/clean/ for analysis.\n")
