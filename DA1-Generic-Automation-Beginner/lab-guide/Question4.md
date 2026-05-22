## Metadata
Question Type : Multiple Choice

## Question
4. Your script emits a structured JSON run report instead of plain-text log lines. Which of the following are *real* benefits of structured output for production automation? (Select all that apply.)

## Options
Option 1: Downstream tools (dashboards, alerting, audit) can parse the report deterministically
Option 2: Errors include machine-readable context (filename, reason) instead of being buried in free-form prose
Option 3: The script becomes faster to execute because JSON serialization is cheaper than printf
Option 4: A schema can be used to validate the report shape automatically in CI / validation

## Answers
Option 1 : 1
Option 2 : 1
Option 3 : 0
Option 4 : 1

## Correct Answer Feedback
Correct. Structured output is about *consumability* — by humans AND by downstream automation. It enables deterministic parsing, machine-readable errors, and schema-based validation. Serialization speed is not a meaningful win at automation scale.

## Incorrect Answer Feedback
Structured output's benefits are about downstream consumption: deterministic parsing (Option 1), machine-readable errors (Option 2), and schema validation (Option 4). Option 3 is incorrect — JSON serialization isn't materially faster than printf at typical scales.

## Tags
automation
structured-output
observability
Foundational

## Number of Retries
1
