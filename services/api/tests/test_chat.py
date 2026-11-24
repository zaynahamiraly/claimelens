from types import SimpleNamespace
import pytest
from fastapi import HTTPException
from pydantic import ValidationError
from app.routers.chat import membership, visible, NewMessage, NewConversation


def user(role, identifier="owner"):
    return SimpleNamespace(id=identifier, profile=SimpleNamespace(role=role))


@pytest.mark.parametrize("role", ["administrator", "supervisor", "claims_officer"])
def test_support_staff_can_follow_client_threads(role):
    membership(user(role), {"client_id": "owner"})


@pytest.mark.parametrize(
    "role,identifier,status",
    [("client", "other", 404), ("finance", "owner", 403), ("unknown", "owner", 403)],
)
def test_chat_membership_rejects_other_clients_and_non_support_roles(
    role, identifier, status
):
    with pytest.raises(HTTPException) as e:
        membership(user(role, identifier), {"client_id": "owner"})
    assert e.value.status_code == status


def test_read_positions_are_individual_and_not_disclosed_to_other_people():
    thread = {
        "client_id": "owner",
        "last_sequence": 5,
        "staff_seen": {"officer": 3},
        "client_seen": 4,
    }
    assert visible(thread, user("client"))["unread_count"] == 1
    assert visible(thread, user("claims_officer", "officer"))["unread_count"] == 2
    assert visible(thread, user("supervisor"))["unread_count"] == 5
    assert "staff_seen" not in visible(thread, user("client"))
    assert "client_seen" not in visible(thread, user("client"))


@pytest.mark.parametrize("text", ["", "   ", "\n\t", "x" * 4001])
def test_messages_require_nonempty_bounded_text(text):
    with pytest.raises(ValidationError):
        NewMessage(text=text, client_message_id="a" * 32)


def test_text_is_preserved_as_plain_text_and_trimmed():
    message = NewMessage(
        text="  <b>Which receipt?</b>\nThank you.  ", client_message_id="a" * 32
    )
    assert message.text == "<b>Which receipt?</b>\nThank you."
    with pytest.raises(ValidationError):
        NewMessage(text="Hello", client_message_id="../other")
    with pytest.raises(ValidationError):
        NewConversation(subject="  ")
