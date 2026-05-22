## Metadata
Question Type : Single Choice

## Question
2. Your script must check whether a service is running and include the result in a JSON report. Which exit-code convention is correct for the script itself?

## Options
Option 1: Exit 0 if the script ran successfully, even if a monitored service is down
Option 2: Exit 1 if any monitored service is not running
Option 3: Exit the number equal to the count of services that are down
Option 4: Exit 0 only when all monitored services are running

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. A script's exit code reflects whether the script itself succeeded, not the outcome of the checks it performed. A service being down is a business condition the script reports on — it is not a script failure. Exit 0 means "I ran and produced a valid report."

## Incorrect Answer Feedback
Exit codes signal whether the automation itself succeeded. Reporting that a service is down is not a script failure; that information belongs in the report output. The correct answer is Option 1.

## Tags
automation
exit-codes
health-check
Basic

## Number of Retries
1
