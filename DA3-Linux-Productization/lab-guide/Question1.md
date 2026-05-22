## Metadata
Question Type : Single Choice

## Question
1. You write a systemd unit for the sample backend that runs `python3 -m http.server`. Which `Type=` value is correct?

## Options
Option 1: `Type=simple` — the ExecStart is a long-running foreground process; systemd considers the service "started" the moment the process is spawned
Option 2: `Type=forking` — the ExecStart immediately forks into the background and exits; systemd tracks the PID file
Option 3: `Type=oneshot` — the ExecStart runs to completion and then the service is "active" with no running process
Option 4: `Type=notify` — the ExecStart sends `sd_notify(READY=1)` to systemd when it's ready

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. `python3 -m http.server` is a long-running foreground process — it does not fork, it does not write a PID file, it does not call `sd_notify`. `Type=simple` is the right match: systemd spawns the process, considers the service active immediately, and monitors the process for the rest of its lifetime.

## Incorrect Answer Feedback
The Python http.server runs in the foreground without forking, without writing a PID file, and without `sd_notify`. `Type=simple` is the match. The correct answer is Option 1.

## Tags
linux
systemd
service-type
Practitioner

## Number of Retries
1
