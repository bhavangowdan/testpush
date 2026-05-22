## Metadata
Question Type : Multiple Choice

## Question
5. Your spec says `TC_APP` is granted membership in role `TRADECONF_RW`, which has per-table grants. Which of the following statements about Oracle role-based grants are TRUE? (Select all that apply.):

## Options
Option 1: Privileges granted via a role are NOT available inside a definer's-rights PL/SQL package — direct grants are required for those

Option 2: A user must be granted `CREATE SESSION` (directly or via a role) to actually connect

Option 3: `REVOKE TRADECONF_RW FROM TC_APP;` removes TC_APP's role membership but does NOT revoke the underlying object grants — those still live with the role

Option 4: Roles can be nested (a role can be granted to another role) up to Oracle's MAX_ROLES limit

## Answers
Option 1 : 1
Option 2 : 1
Option 3 : 1
Option 4 : 1

## Tags
oracle
roles
grants
security
Practitioner

## Number of Retries
1