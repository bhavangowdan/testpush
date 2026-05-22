## Metadata
Question Type : Single Choice

## Question
2. Your automation needs to install nginx and PostgreSQL idempotently — running it twice must not fail and must not "re-install" the packages. Which Bash pattern is correct?

## Options
Option 1: `apt-get install nginx postgresql` — apt is always idempotent; nothing to add
Option 2: `apt-get install -y nginx postgresql` — `-y` makes apt non-interactive and exit 0 when packages are already installed
Option 3: `dpkg -i nginx_*.deb postgresql_*.deb` — dpkg is more reliable than apt
Option 4: Wrap apt in `if ! dpkg -s nginx; then apt-get install nginx; fi` per package — manual presence check is the only idempotent path

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. `apt-get install -y <pkg>` is idempotent by design: if the package is already at the target version, apt does nothing and exits 0. The `-y` flag is required to make the install non-interactive (without it, apt prompts and an automation pipeline hangs). The manual presence check in Option 4 works but is unnecessary — apt's "already installed" path is reliable.

## Incorrect Answer Feedback
`apt-get install -y` is idempotent: if the package is already installed at the target version, it does nothing and exits 0. The `-y` makes it non-interactive (required for unattended automation). Manual presence checks are unnecessary. The correct answer is Option 2.

## Tags
linux
package-management
idempotency
Practitioner

## Number of Retries
1
