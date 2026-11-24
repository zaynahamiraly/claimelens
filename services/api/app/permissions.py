"""Server-side permissions: administrative access does not imply clinical authority."""

from fastapi import HTTPException

PERMISSIONS = {
    "claims.review",
    "claims.assign",
    "claims.decide",
    "payments.record",
    "users.manage",
    "analytics.view",
    "audit.view",
}
DEFAULTS = {
    "client": set(),
    "claims_officer": {"claims.review", "analytics.view", "audit.view"},
    "supervisor": {
        "claims.review",
        "claims.assign",
        "claims.decide",
        "analytics.view",
        "audit.view",
    },
    "finance": {"payments.record", "analytics.view", "audit.view"},
    "administrator": {"users.manage", "claims.assign", "analytics.view", "audit.view"},
}


def permissions(profile):
    if profile.role == "client":
        return set()
    return DEFAULTS.get(profile.role, set()) | (
        set(getattr(profile, "permissions", [])) & PERMISSIONS
    )


def require(user, permission):
    if permission not in permissions(user.profile):
        raise HTTPException(
            403, "Your account does not have permission for this action."
        )
