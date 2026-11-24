"""Operator-only encrypted backup and restore of Firestore application data/files.

Passwords are entered interactively; they are never command-line arguments.
Firebase Authentication accounts remain managed by Firebase and are not exported.
"""
import argparse
from getpass import getpass
import json
import os
from pathlib import Path, PurePosixPath
import secrets
import tempfile
import zipfile

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

COLLECTIONS = ['profiles', 'claims', 'claim_documents', 'claim_extracted_fields', 'claim_processing_jobs', 'processing_queue', 'document_fingerprints', 'claim_information_requests', 'claim_appeals', 'audit_events', 'notifications', 'configuration', 'support_threads', 'support_messages', 'support_message_requests']
MAGIC = b'CLB1'


def derive(password, salt):
    if len(password) < 12:
        raise ValueError('Use a backup passphrase of at least 12 characters.')
    return PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=600_000).derive(password.encode())


def create_backup(root, records, project, output, password):
    root, output = Path(root), Path(output)
    salt, nonce = secrets.token_bytes(16), secrets.token_bytes(12)
    key = derive(password, salt)
    with tempfile.TemporaryFile() as temporary:
        with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr('database.json', json.dumps({'version': 1, 'project': project, 'collections': records}, default=str))
            for folder in ('files', 'metadata'):
                base = root / folder
                if base.exists():
                    for file in base.rglob('*'):
                        if file.is_file() and not file.is_symlink():
                            archive.write(file, 'storage/' + file.relative_to(root).as_posix())
            for name in ('.signing-key', '.encryption-key'):
                if (root/name).exists():
                    archive.write(root/name, 'storage/' + name)
        temporary.seek(0)
        encryptor = Cipher(algorithms.AES(key), modes.GCM(nonce)).encryptor()
        header = MAGIC+salt+nonce
        encryptor.authenticate_additional_data(header)
        with output.open('xb') as target:
            os.chmod(output, 0o600)
            target.write(header)
            while chunk := temporary.read(1024*1024):
                target.write(encryptor.update(chunk))
            target.write(encryptor.finalize())
            target.write(encryptor.tag)


def open_backup(path, password):
    temporary = tempfile.TemporaryFile()
    try:
        with Path(path).open('rb') as source:
            header = source.read(32)
            if header[:4] != MAGIC:
                raise ValueError('This is not a ClaimLens backup.')
            source.seek(-16, 2); tag = source.read(16)
            length = source.tell()-48
            source.seek(32)
            decryptor = Cipher(algorithms.AES(derive(password, header[4:20])), modes.GCM(header[20:32], tag)).decryptor()
            decryptor.authenticate_additional_data(header)
            while length > 0:
                chunk = source.read(min(length, 1024*1024))
                if not chunk:
                    raise ValueError('The backup is incomplete.')
                temporary.write(decryptor.update(chunk)); length -= len(chunk)
            temporary.write(decryptor.finalize())
        temporary.seek(0)
        archive = zipfile.ZipFile(temporary)
        for name in archive.namelist():
            path = PurePosixPath(name)
            if path.is_absolute() or '..' in path.parts or '\\' in name or ':' in name:
                raise ValueError('Unsafe backup path.')
        manifest = json.loads(archive.read('database.json'))
        if manifest.get('version') != 1 or set(manifest.get('collections', {})) - set(COLLECTIONS):
            raise ValueError('Unsupported backup schema.')
        return temporary, archive, manifest
    except Exception:
        temporary.close()
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['create', 'verify', 'restore'])
    parser.add_argument('file')
    parser.add_argument('--destination', help='A new empty directory for recovered storage.')
    parser.add_argument('--apply-database', action='store_true', help='Create missing database records; never overwrite conflicting records.')
    args = parser.parse_args()
    password = getpass('Backup passphrase: ')
    from .config import get_settings
    settings = get_settings()
    if args.action == 'create':
        if password != getpass('Confirm backup passphrase: '):
            raise ValueError('Passphrases do not match.')
        from .firebase import firebase_app
        from firebase_admin import firestore
        db = firestore.client(firebase_app())
        records = {name: {row.id: row.to_dict() for row in db.collection(name).stream()} for name in COLLECTIONS}
        create_backup(settings.document_storage_path, records, settings.firebase_project_id, args.file, password)
        print('Encrypted backup created. Keep the passphrase separately and verify the backup before relying on it.')
        return
    temporary, archive, manifest = open_backup(args.file, password)
    try:
        print('Backup verified:', sum(len(rows) for rows in manifest['collections'].values()), 'database records.')
        if args.action != 'restore':
            return
        if not args.destination:
            raise ValueError('Supply --destination with a new empty storage directory.')
        destination = Path(args.destination).resolve()
        if destination.exists() and any(destination.iterdir()):
            raise ValueError('The recovery destination must be empty.')
        if manifest['project'] != settings.firebase_project_id:
            raise ValueError('The backup belongs to a different Firebase project.')
        db = None
        if args.apply_database:
            from .firebase import firebase_app
            from firebase_admin import firestore
            db = firestore.client(firebase_app())
            for name, rows in manifest['collections'].items():
                for identifier, record in rows.items():
                    existing = db.collection(name).document(identifier).get()
                    if existing.exists and existing.to_dict() != record:
                        raise ValueError('Conflicting database records exist. Restore into an empty recovery project or resolve conflicts first.')
        destination.mkdir(parents=True, exist_ok=True, mode=0o700)
        for name in archive.namelist():
            if name.startswith('storage/'):
                target = destination.joinpath(*PurePosixPath(name).parts[1:])
                target.parent.mkdir(parents=True, exist_ok=True)
                with target.open('xb') as output:
                    os.chmod(target, 0o600)
                    with archive.open(name) as source:
                        while chunk := source.read(1024*1024):
                            output.write(chunk)
        if db:
            from google.api_core.exceptions import AlreadyExists
            for name, rows in manifest['collections'].items():
                for identifier, record in rows.items():
                    try:
                        db.collection(name).document(identifier).create(record)
                    except AlreadyExists:
                        pass
        print('Recovery files written. Point DOCUMENT_STORAGE_PATH to the recovered directory after verification. Firebase Authentication accounts are not restored by this command.')
    finally:
        archive.close(); temporary.close()


if __name__ == '__main__':
    main()
