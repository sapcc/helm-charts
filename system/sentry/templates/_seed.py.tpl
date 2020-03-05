import click
import os
from sentry.app import locks
from sentry.utils.locking import UnableToAcquireLock
# We use the 'upgrade' lock to avoid running in a half initialized database
# https://github.com/getsentry/sentry/blob/d45ae1d1b7a05ca46724a106447320d4932269b7/src/sentry/runner/commands/upgrade.py#L53
lock = locks.get('upgrade', duration=0)

def ensure_user(email, password):
    try:
        user = User.objects.get(email=email)
        click.echo("User already exists")
        if not user.check_password(password):
            user.set_password(password)
            user.save()
            click.echo("Password updated")
        return user

    except User.DoesNotExist:
        superuser = True
        #copied from https://github.com/getsentry/sentry/blob/master/src/sentry/runner/commands/createuser.py
        user = User(
            email=email,
            username=email,
            is_superuser=superuser,
            is_staff=superuser,
            is_active=True,
        )
        user.set_password(password)
        user.save()
        click.echo('User created: %s' % (email,))
        if settings.SENTRY_SINGLE_ORGANIZATION:
            from sentry.models import (
                Organization, OrganizationMember, OrganizationMemberTeam, Team
            )

            org = Organization.get_default()
            if superuser:
                role = roles.get_top_dog().id
            else:
                role = org.default_role
            member = OrganizationMember.objects.create(
                organization=org,
                user=user,
                role=role,
            )

            # if we've only got a single team let's go ahead and give
            # access to that team as its likely the desired outcome
            teams = list(Team.objects.filter(organization=org)[0:2])
            if len(teams) == 1:
                OrganizationMemberTeam.objects.create(
                    team=teams[0],
                    organizationmember=member,
                )
            click.echo('Added to organization: %s' % (org.slug,))
            org.default_role='manager'
            org.name=os.getenv('ORGANIZATION_NAME', 'Sentry')
            org.slug=os.getenv('ORGANIZATION_SLUG', 'sentry')
            org.save()
            click.echo('Changed default role to manager')
        return user

def ensure_api_token(user, token):
    try:
        ApiToken.objects.get(token=token)
    except ApiToken.DoesNotExist:
        token = ApiToken.objects.create(
             user=user,
             scope_list=["project:read", "project:write", "project:delete", "team:read", "team:write", "org:read", "org:write", "member:read", "member:write", "event:read"],
             token=token,
             refresh_token=None,
             expires_at=None,
        )

        click.echo("Token created")

try:
    with lock.acquire():
        click.echo("Lock aquired")
        user = ensure_user(os.environ['ADMIN_EMAIL'], os.environ['ADMIN_PASSWORD'])
        ensure_api_token(user, os.environ['ADMIN_API_TOKEN'])
except UnableToAcquireLock:
    raise click.ClickException('Unable to acquire lock.')




