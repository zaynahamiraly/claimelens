from urllib.parse import parse_qs, urlparse
import base64
import pytest
from fastapi import HTTPException
from app.documents import LocalDocuments


def parameters(url):
    query = parse_qs(urlparse(url).query)
    return query['document'][0], int(query['expires'][0]), query['signature'][0]


def test_private_file_roundtrip_and_signed_link(tmp_path):
    store = LocalDocuments(tmp_path, 'http://127.0.0.1:8000')
    path = 'user/claim/document.pdf'
    store.upload(path, b'%PDF-synthetic', 'application/pdf')
    assert store.download(path) == b'%PDF-synthetic'
    target, mime = store.verify(*parameters(store.signed_url(path)))
    assert target.read_bytes() == b'%PDF-synthetic'
    assert mime == 'application/pdf'
    store.delete(path)
    with pytest.raises(HTTPException) as error:
        store.download(path)
    assert error.value.status_code == 404


def test_forged_or_expired_link_cannot_read_file(tmp_path):
    store = LocalDocuments(tmp_path, 'http://localhost')
    store.upload('user/claim/doc.png', b'image', 'image/png')
    document, expires, signature = parameters(store.signed_url('user/claim/doc.png'))
    for values in [(document, expires, 'wrong'), (document, 0, signature), (base64.urlsafe_b64encode(b'other/claim/doc.png').decode(), expires, signature)]:
        with pytest.raises(HTTPException) as error:
            store.verify(*values)
        assert error.value.status_code == 403


@pytest.mark.parametrize('path', ['../secret', '/absolute/path', 'user/../secret', 'user/claim/../../secret', 'user/claim/C:\\secret', 'user/claim/..'])
def test_path_traversal_is_rejected(tmp_path, path):
    with pytest.raises(HTTPException):
        LocalDocuments(tmp_path, 'http://localhost').file(path)


def test_upload_never_overwrites_an_existing_file(tmp_path):
    store = LocalDocuments(tmp_path, 'http://localhost')
    store.upload('user/claim/document.pdf', b'first', 'application/pdf')
    with pytest.raises(FileExistsError):
        store.upload('user/claim/document.pdf', b'second', 'application/pdf')
    assert store.download('user/claim/document.pdf') == b'first'
