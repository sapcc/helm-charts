This check finds alert rules that do not have all required labels and annotations.

#### Why is this a problem?

Without the `severity` and `support_group` label, alerts cannot be routed to the right Slack channels. Without the `playbook`
label, operators will not know how to fix the alert. Without the `summary` and `description` annotations, operators
will not know what the alert is about.

#### How to fix?

Add the missing labels and annotations, as reported. Note that `severity` only accepts the values `critical`, `warning`
and `info`.
