# Evidence-Based Milestone Deadlines

Compute the deadline of a GitHub Milestone based on corrected issue
estimates.

* incurs a low-impact process on assignees
* puts estimates near all relevant details
* permits estimate revision as easily as providing the original estimate
* fosters single-source-of-truth for issue milestones and assignments
* adjusts the deadline when things are added, reopened, moved, or closed
* compensates for past estimate track-record
* does not increase the number of developer tools

## Estimating

An issue has an estimate if has a label such as:

    2 days
    14 hours
    1 week
    3 points

or more flexibly if any of its comments have a line of the format:

    estimated 2 days
    14hr estimate
    eta 0.9 week per mrmanager
    3 points

Comment estimates may be made by the assignee, other potential
assignee(s), or both.

## Computations

The Closed Issues Estimates *(CIE)* is the sum of estimates of closed
issues, grouped by an assignee.

Available Time *(AT)* is a function that computes the assignee
availability over a timespan, excluding their time off, holidays, or
other jobs.

For each assignee, the Velocity *(V)* is the ratio:

    V = CIE / AT(start..now)

A *V* of 100% means their estimates were accurate, whereas 200% means
they took half as long as estimated.

Open Issues Estimate *(OIE)* is the sum of estimates of open issues,
grouped by an assignee.

A Corrected Open Issues Estimate *(COIE)* is computed for each
assignee by:

    COIE = OIE * AT(now..COIE) / V

Issues with non-assignee estimates are potentially manually
(re)assignable, or Sheddable Issues *(SI)*.

## Reporting

The milestone's deadline is set to the last assignee's *COIE*.

The milestone's description is updated with an estimate report,
ordered by assignee's *COIE* (labeled `done`).  For estimate
calibration, the *OIE*, *AT(now..COIE)*, and *V* are revealed (labeled
`estimate`, `avail.`, and `velocity`).  For rebalancing, some *SI* IDs
are listed (labeled `sheddable`).

    | assignee |    done | estimate | avail. | velocity | sheddable |
    |----------|--------:|---------:|-------:|---------:|-----------|
    | @user1   | 10 days |  10 days |    88% |     110% | #239      |
    | @user2   | 68 days | 138 days |   100% |     200% | #226      |
    | @user3   |     TBD |          |        |          |           |

which renders like:

| assignee    |    done | estimate | avail. | velocity | sheddable |
|-------------|--------:|---------:|-------:|---------:|-----------|
| [@user1](#) | 10 days |  10 days |    88% |     110% | [#239](#) |
| [@user2](#) | 68 days | 138 days |   100% |     200% | [#226](#) |
| [@user3](#) |     TBD |          |        |          |           |

## Caveats

If either *CIE* or *AT(start..now)* are 0, *V* is 100%.  This
serves estimating before commencing work.

If any open issue for the milestone does not have an estimate, or if
the milestone has a prior open milestone without a deadline, the
milestone deadline is not computable.  The deadline is thus unset.

If the open issue is assigned but without an estimate, the assignee's
*COIE* is `TBD`.  This calls out those who have not provided
estimates.

Closed issues without estimates are assumed to take 0 time, and thus
their assignment is irrelevant.  This encourages providing estimates,
even retroactively.

Open issues without assignees but with comment estimates are
deadline-optimally distributed among the commenters who provided
estimates.

Open issues without assignees but with labeled estimates are
deadline-optimally distributed among the discovered assignees.

## Configuration

The milestone description may also have lines specifying the following
configuration options.

### report units

The scale of *COIE* and *OIE*, specified in the report header:

    estimates (hours)
    estimates (days)
    estimates (weeks)
    estimates (months)
    estimates (points)

If absent, the scale is days.

### conversion ratios

*AT* baseline, specified in the milestone description:

    user1: 7hours/day, 2days/week
    user2: 10hr/day, 6d/wk
    36hours/week
    4pt/week

If absent:

    8hours/day
    40hours/week
    22days/month
    1point/week

### time off

*AT* exceptions, specified in the milestone description:

    user1: vacation 2014-05-09 to 2014-05-12
    user2: unavailable 2014-05-14
    holiday 2014-05-22

### start time

Assignee's start on the milestone, specified in the milestone
description:

    user2: started 2014-05-01
    started 2014-04-01

If absent, it's the earliest of the assignee's closed issues minus
estimate.  If none of their issues are closed, it defaults to now.

### milestone order

Prior milestones, specified in the milestone description:

    after milestone name
    after milestone_id

The earliest start date for each assignee in this milestone is the
latest *COIE* of prior milestone.

## Todo

Non-linear *V*, if longer estimates are habitually less accurate
than shorter.

Limit unassigned issues to a subset of potential assignees.

End time or total units of time available.
