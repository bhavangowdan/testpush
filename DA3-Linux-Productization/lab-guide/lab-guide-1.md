## Linux Productization — Ubuntu Hardening + Service Stack Build-out

### Estimated duration: 90 minutes

### What this assessment is

This is the **Linux Productization** assessment — the one that proves Nedbank's infrastructure engineers can automate the canonical Linux sysadmin lifecycle (harden → install → configure → wire services together → provision users → schedule tasks) end-to-end. Every task tests a real Linux skill, expressed through an automation tool.

You pick the tool you already know: **Bash, Ansible, or Python**. The seven validations grade the *outcome* — is the system in the required state? — regardless of which tool got it there.

### What this assessment is NOT

- Not an Azure infrastructure exam. You won't touch the Azure portal. All work happens on the deployed VM via SSH.
- Not a coding-style review. The validations don't read your code.
- Not closed-book — **AI assistants are permitted**. We've designed the problem so generated code alone is not enough; the specs are precise, the validations check effective state, and you'll need to debug against the actual running system.

### Assessment Environment

1. One Ubuntu 22.04 LTS VM is deployed: **`LNX-<inject key="DeploymentID" enableCopy="false"/>`** in your sandbox resource group **`rg-da3-<inject key="DeploymentID" enableCopy="false"/>`**.

1. You have **read-only** Azure access — all your work happens on the VM via SSH. The public DNS name and **VM Admin Password** are shown on the **Environment Details** tab.

   * SSH: `ssh azureuser@<linux-dns-name>` then enter the VM Admin Password.

1. **The VM is bare**. Ubuntu 22.04 LTS only — your automation does the rest. Pre-installed tools you may use:

   * `bash`, `ansible`, `python3` + `pyyaml`, `jq`, `curl`, `vim`, `tmux`, `openssl`

1. **All input specifications are pre-staged under `/opt/spec/`** — these files are complete; consume them verbatim from your automation:

   | Path | What's in it |
   |---|---|
   | `/opt/spec/sshd.conf.target` | Target SSH config values |
   | `/opt/spec/ufw.rules.target` | Target ufw rules |
   | `/opt/spec/pg.spec.yaml` | PostgreSQL role + DB spec |
   | `/opt/spec/nginx.conf.target` | Target nginx site config (drop into `/etc/nginx/sites-available/`) |
   | `/opt/spec/certs/bankapp.crt` + `.key` | Pre-generated self-signed TLS cert (deploy to `/etc/ssl/certs/` and `/etc/ssl/private/`) |
   | `/opt/spec/sample-app.service.template` | systemd unit for the Python http.server backend |
   | `/opt/spec/sample-app-content/index.html` | The HTML the backend serves (used to prove the reverse-proxy works) |
   | `/opt/spec/users.yaml` | Users + groups + sudo spec |
   | `/opt/spec/users/<name>/authorized_keys` | Pre-generated SSH public keys per user |
   | `/opt/spec/cron.yaml` | Cron task spec |
   | `/opt/spec/secrets/bankapp.pw` | Pre-generated PostgreSQL password for `bankapp` role (root-only, mode 0400) |

### Level: Intermediate (Practitioner)

### Assessment Objective

Demonstrate that you can productize the build-out of a Linux host — drive automation end-to-end across hardening, service installation, TLS, user provisioning, and scheduled tasks, with the system converging on the required state per the inputs in `/opt/spec/`.

---

## Scenario

A bank needs a new Linux host brought into service for hosting a small backend application behind a TLS-terminated reverse proxy, with a PostgreSQL database, a defined user/group layout, and a daily reporting cron task. You are handed a bare Ubuntu 22.04 VM and the complete input spec under `/opt/spec/`.

Your job: write **one** automation (in Bash, Ansible, or Python) that turns the bare VM into the required production state. The automation must be idempotent — running it twice in a row must leave the system in the same end state.

---

## Pre-work — Linux productization principles

Six short questions on the concepts your automation needs to demonstrate.

<question source="Question1.md" />

<br>

<question source="Question2.md" />

<br>

<question source="Question3.md" />

<br>

<question source="Question4.md" />

<br>

<question source="Question5.md" />

<br>

<question source="Question6.md" />

<br>

---

## Your deliverables

Build an automation that satisfies all seven validations below. Hit **Validate** after each task to score it; iterate as needed within the 90-minute window.

### Task 1 — SSH hardening

Your automation must update `/etc/ssh/sshd_config` so the EFFECTIVE config matches `/opt/spec/sshd.conf.target`. After your automation runs, the values returned by `sudo sshd -T` must match the target file exactly for each listed directive (`PermitRootLogin`, `PasswordAuthentication`, `MaxAuthTries`, `ChallengeResponseAuthentication`, `UsePAM`, `X11Forwarding`).

> ⚠️ Don't lock yourself out — `sshd -T` runs in test mode and won't break your session. Apply changes carefully and reload sshd (`systemctl reload ssh`).

<validation step="replace-me-uuid-01-ssh-hardening" />

### Task 2 — ufw firewall rules

Install + enable `ufw`. Default-deny incoming, default-allow outgoing, exactly these three allow rules: `22/tcp`, `80/tcp`, `443/tcp`. Spec: `/opt/spec/ufw.rules.target`.

<validation step="replace-me-uuid-02-ufw-rules" />

### Task 3 — PostgreSQL: install, role, database

Install PostgreSQL via apt. Create the role `bankapp` with the password from `/opt/spec/secrets/bankapp.pw` (LOGIN, NOSUPERUSER). Create the database `ledger` owned by `bankapp` with `UTF8` encoding. Spec: `/opt/spec/pg.spec.yaml`.

<validation step="replace-me-uuid-03-postgres" />

### Task 4 — nginx + TLS reverse proxy

Install nginx. Deploy the cert and key from `/opt/spec/certs/` to `/etc/ssl/certs/bankapp.crt` and `/etc/ssl/private/bankapp.key`. Install the site config from `/opt/spec/nginx.conf.target` so 443 reverse-proxies to `localhost:5000` and 80 redirects to HTTPS. The HTTPS response body must contain "DA3 sample backend" (proves the proxy chain works).

<validation step="replace-me-uuid-04-nginx-tls" />

### Task 5 — Sample app systemd service

Install `sample-app.service` (template at `/opt/spec/sample-app.service.template`) at `/etc/systemd/system/sample-app.service`, enable + start it. The unit runs `python3 -m http.server --bind 127.0.0.1 5000` from `/opt/spec/sample-app-content/`. The backend must respond on 127.0.0.1:5000 with the seeded `index.html` (so nginx in Task 4 can proxy to it).

<validation step="replace-me-uuid-05-sample-app-service" />

### Task 6 — Users, groups, SSH keys, sudo

Provision the users + groups in `/opt/spec/users.yaml`. Deploy each user's `authorized_keys` from `/opt/spec/users/<name>/`. Add carol's NOPASSWD sudo rule (`ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx`) — drop into `/etc/sudoers.d/carol`.

<validation step="replace-me-uuid-06-users-groups" />

### Task 7 — Cron task

Install the cron task from `/opt/spec/cron.yaml` — schedule `0 6 * * *`, command `df -h | tee /var/log/disk-report.log`, run as root. Either `/etc/cron.d/<filename>` or root's crontab is acceptable.

<validation step="replace-me-uuid-07-cron" />

---

## Where to place your automation

The validation scripts don't look at your automation script directly — they check the resulting system state. Place your script anywhere you like, but a clean location is:

- `/home/azureuser/automation/configure.sh` (Bash)
- `/home/azureuser/automation/configure.yml` (Ansible)
- `/home/azureuser/automation/configure.py` (Python)

For Ansible, you can run locally with `ansible-playbook -i 'localhost,' -c local configure.yml`.

---

## Tips for fast iteration

```bash
# Tail every relevant log while you iterate
sudo journalctl -u sshd -u ssh -u postgresql -u nginx -u sample-app -f

# Probe nginx + sample backend after each iteration
curl -kI https://127.0.0.1/
curl -s http://127.0.0.1:5000/

# Verify users + groups
getent passwd alice bob carol; getent group webops dbops; sudo -ln -U carol
```

---

## Validation

> Validate each task by clicking the **Validate** button next to its validation block.
>
> Your automation must be idempotent — re-running it must produce no errors and leave the system in the same end state. The validations don't explicitly test this, but a non-idempotent script will fail intermittently as you iterate.

### Success criteria

1. All seven validations (Tasks 1–7) return **Success**.
2. The six pre-work questions are scored automatically by the portal.
3. Overall pass: ≥ 60% across questions + tasks.

### Lab Validation tab — usage

1. After completing each task, visit the **Lab Validation** tab and click **VALIDATE** under Actions.
2. If validation shows **Success** for all seven tasks, you've passed.
3. If validation shows **Fail**, hover over the `i` icon to read the root-cause hint, fix the issue, and re-validate.
4. For platform issues, contact `labs-support@spektrasystems.com`.
