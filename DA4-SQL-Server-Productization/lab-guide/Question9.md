## Metadata
Question Type : Multiple Choice

## Question
3. Which of the following are valid reasons to write automation output as structured JSON rather than plain text? (Select all that apply.)

## Options
Option 1: Downstream scripts and tools can parse the output without fragile string-splitting
Option 2: JSON output can be validated against a schema to catch missing or malformed fields
Option 3: JSON is faster to write to disk than plain text
Option 4: Monitoring and alerting platforms can ingest JSON natively via log-parsing rules

## Answers
Option 1 : 1
Option 2 : 1
Option 4 : 1

## Correct Answer Feedback
Correct. Structured JSON output enables reliable downstream parsing, schema validation, and native ingestion by monitoring platforms. Write speed is not a meaningful advantage of JSON over plain text.

## Incorrect Answer Feedback
JSON is not faster to write than plain text (it is usually larger). The correct reasons are: reliable parsing, schema validation, and native monitoring ingestion.

## Tags
automation
structured-output
json
Basic

## Number of Retries
1
