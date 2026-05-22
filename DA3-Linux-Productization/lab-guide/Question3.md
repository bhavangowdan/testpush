## Metadata
Question Type : Single Choice

## Question
3. After your automation writes a new `/etc/nginx/sites-available/bankapp` file, which command applies the change with the least disruption?

## Options
Option 1: `systemctl restart nginx` — fully stops and starts nginx; brief connection-refused window
Option 2: `systemctl reload nginx` — sends SIGHUP; nginx re-reads config and hot-swaps workers; existing connections drain gracefully
Option 3: `pkill -HUP nginx` — equivalent to reload but bypasses systemd
Option 4: `nginx -s reload` — equivalent to reload, invoked via nginx CLI

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. `systemctl reload nginx` triggers nginx's graceful reload: it sends SIGHUP, nginx re-reads config, starts new worker processes with the new config, and waits for existing workers to drain their connections before terminating them. No connection-refused window. `systemctl restart` works but is more disruptive. Options 3 and 4 are functionally equivalent to reload but bypass systemd's state tracking — fine in a pinch, not the canonical answer for production automation.

## Incorrect Answer Feedback
nginx reload (`systemctl reload nginx`) is the graceful path: hot-swap workers, drain existing connections, no connection-refused window. Restart works but is more disruptive. The correct answer is Option 2.

## Tags
linux
nginx
graceful-reload
Practitioner

## Number of Retries
1
