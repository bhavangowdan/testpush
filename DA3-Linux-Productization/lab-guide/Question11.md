## Metadata
Question Type : Single Choice

## Question
5. When compressing log files for archiving, which approach correctly preserves the original log date for retention decisions?

## Options
Option 1: Parse the date from the filename (e.g., app-2024-06-15.log) and use that for age calculations
Option 2: Use the file's mtime (last-modified timestamp) for age calculations
Option 3: Use the file's ctime (change time) for age calculations
Option 4: Use the current system date minus the file size in bytes as a heuristic

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. File mtime and ctime can be altered by copies, moves, restores, or system clock changes. The date encoded in the filename is the authoritative log date and should be used for retention decisions.

## Incorrect Answer Feedback
mtime and ctime are unreliable for retention because they change when files are moved or restored. Always parse the authoritative date from the filename. The correct answer is Option 1.

## Tags
automation
log-lifecycle
file-management
Intermediate

## Number of Retries
1
