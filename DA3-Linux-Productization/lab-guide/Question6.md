## Metadata
Question Type : Single Choice

## Question
6. Your automation enables ufw with `default deny incoming` and `default allow outgoing`, then adds `allow 22/tcp`. In what ORDER does ufw evaluate these for an incoming SSH packet?

## Options
Option 1: ufw checks the user-defined rules first; if no rule matches, it falls through to the default policy
Option 2: ufw checks the default policy first; default-deny short-circuits and SSH is blocked regardless of allow rules
Option 3: ufw evaluates rules in reverse order of insertion; the most recent rule wins
Option 4: ufw randomly picks one rule per packet to keep the firewall stateless

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. ufw (like iptables underneath) evaluates user-defined rules first; the default policy is the "fall-through" only when no explicit rule matches. So `default deny incoming` + `allow 22/tcp` means: incoming TCP on port 22 matches the allow rule (accept), everything else falls through to the default deny. This is also why rule order matters for overlapping rules — first match wins.

## Incorrect Answer Feedback
Specific rules are evaluated before defaults; the default policy is the fall-through when no rule matches. `default deny incoming` plus `allow 22/tcp` means SSH on 22 is allowed and everything else is denied. The correct answer is Option 1.

## Tags
linux
firewall
ufw
Practitioner

## Number of Retries
1
