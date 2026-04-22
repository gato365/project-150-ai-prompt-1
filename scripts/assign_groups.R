# ============================================================
# assign_groups.R
# STAT 252 Spring 2026 — AI Prompting Experiment
# Run this after the pretest closes on 4/27
#
# What it does:
#   1. Reads Canvas pretest export (CSV)
#   2. Stratifies students by pretest score (low/mid/high)
#   3. Randomly assigns to 3 groups, balanced within strata
#   4. Assigns 4-digit participant codes (1xxx / 2xxx / 3xxx)
#   5. Writes group_assignments.csv
#   6. Writes email_list.csv (name, email, code, group)
#   7. Prints GROUP_LOOKUP JS block to paste into experiment.html
# ============================================================

library(tidyverse)
set.seed(252)  # reproducible assignment

# ── CONFIG ──────────────────────────────────────────────────
CANVAS_EXPORT   <- here::here("data", "canvas_pretest_raw.csv")
OUTPUT_DIR      <- here::here("data")

# Canvas column names — adjust if export differs
COL_STUDENT     <- "Student"
COL_ID          <- "ID"
COL_EMAIL       <- "SIS Login ID"   # usually Cal Poly email
COL_SCORE       <- "Score"
MAX_SCORE       <- 10               # adjust to your pretest total

GROUPS          <- c("control", "nostructure", "structure")
CODE_PREFIX     <- c(control = "1", nostructure = "2", structure = "3")

# ── READ CANVAS EXPORT ───────────────────────────────────────
raw <- read_csv(CANVAS_EXPORT, show_col_types = FALSE)

# Drop Canvas summary rows (they have NA scores)
students <- raw |>
  filter(!is.na(.data[[COL_SCORE]]),
         .data[[COL_STUDENT]] != "Student, Test") |>
  rename(
    name   = all_of(COL_STUDENT),
    canvas_id = all_of(COL_ID),
    email  = all_of(COL_EMAIL),
    score  = all_of(COL_SCORE)
  ) |>
  mutate(
    score = as.numeric(score),
    pct   = score / MAX_SCORE
  ) |>
  select(name, canvas_id, email, score, pct)

cat("Students found:", nrow(students), "\n")
cat("Score summary:\n")
print(summary(students$score))

# ── STRATIFIED RANDOM ASSIGNMENT ────────────────────────────
# Split into terciles so each group has similar prior knowledge
students <- students |>
  mutate(
    strata = cut(pct,
                 breaks = quantile(pct, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
                 labels = c("low", "mid", "high"),
                 include.lowest = TRUE)
  )

assign_balanced <- function(df) {
  n <- nrow(df)
  # Cycle through groups to balance
  base <- rep(GROUPS, length.out = n)
  shuffled <- sample(base)
  df |> mutate(group = shuffled)
}

assigned <- students |>
  group_by(strata) |>
  group_modify(~ assign_balanced(.x)) |>
  ungroup()

# ── ASSIGN PARTICIPANT CODES ─────────────────────────────────
assigned <- assigned |>
  group_by(group) |>
  mutate(
    seq_num = row_number(),
    code = paste0(CODE_PREFIX[group], sprintf("%03d", seq_num))
  ) |>
  ungroup()

# ── CHECK BALANCE ────────────────────────────────────────────
cat("\n── Group Sizes ──────────────────────────────\n")
print(count(assigned, group))

cat("\n── Mean Pretest Score by Group ──────────────\n")
assigned |>
  group_by(group) |>
  summarise(
    n         = n(),
    mean_score = round(mean(score, na.rm = TRUE), 2),
    sd_score   = round(sd(score, na.rm = TRUE), 2)
  ) |>
  print()

# ── WRITE OUTPUTS ────────────────────────────────────────────

# Full assignment table (keep for research records)
write_csv(
  assigned |> select(code, group, canvas_id, name, email, score, strata),
  file.path(OUTPUT_DIR, "group_assignments.csv")
)
cat("\nWrote: data/group_assignments.csv\n")

# Email list (name, email, code only — minimal PII for sending)
write_csv(
  assigned |> select(name, email, code, group),
  file.path(OUTPUT_DIR, "email_list.csv")
)
cat("Wrote: data/email_list.csv\n")

# ── PRINT JS LOOKUP TABLE ────────────────────────────────────
cat("\n── Paste this into experiment.html (GROUP_LOOKUP) ──────\n\n")
cat("const GROUP_LOOKUP = {\n")

for (i in seq_len(nrow(assigned))) {
  row <- assigned[i, ]
  cat(sprintf('  "%s": "%s",\n', row$code, row$group))
}
cat("};\n")

cat("\n── Done. Verify group_assignments.csv before emailing. ──\n")
