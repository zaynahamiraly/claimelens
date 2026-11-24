"""Generate a reproducible, credential-free dissertation handover bundle."""
from pathlib import Path
import ast
import hashlib
import json
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/dissertation'
sys.path.insert(0, str(ROOT / 'services/api'))
from app.main import app


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    paths = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard'], cwd=ROOT,
        text=True).splitlines()
    selected = sorted({p for p in paths if (
        p.startswith('mobile/claimlens_mobile/lib/') and p.endswith('.dart')
        or p.startswith('services/api/app/') and p.endswith('.py')
        or p.startswith('firebase/') and p.endswith('.rules')
        or p.startswith('mobile/claimlens_mobile/android/app/src/main/')
        and Path(p).suffix in {'.xml', '.kt'}
        or p in {'mobile/claimlens_mobile/pubspec.yaml', 'services/api/requirements.txt',
                 'mobile/claimlens_mobile/android/app/build.gradle.kts',
                 'mobile/claimlens_mobile/android/settings.gradle.kts'})})
    schema = app.openapi()
    (OUT / 'ClaimLens_API_Schema.json').write_text(json.dumps(schema, indent=2), encoding='utf-8')
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    index = []
    sections = ['# ClaimLens — Numbered Source Reference',
        'Generated from the local working tree. This is an implementation reference, not evidence of production deployment.',
        f'Parent Git revision: `{revision}`. Working-tree changes may be newer; SHA-256 hashes below identify the exact files.',
        'Read ClaimLens_Project_Portfolio.md first. Source lines are exact UTF-8 text, prefixed with line numbers. '
        'Private environment files, service-account keys, SDK client configuration, runtime data, uploads and test credentials are excluded. '
        'Use this reference to explain code; never infer unimplemented features from function names.']
    for name in selected:
        path = ROOT / name
        content = path.read_text(encoding='utf-8-sig')
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        lines = content.splitlines()
        symbols = []
        if path.suffix == '.py':
            for node in ast.walk(ast.parse(content)):
                if isinstance(node, (ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
                    symbols.append(f'`{node.name}`: L{node.lineno}–L{node.end_lineno}')
        elif path.suffix == '.dart':
            symbols = [f'`{m.group(1)}`: L{content[:m.start()].count(chr(10))+1}'
                       for m in re.finditer(r'\bclass\s+(\w+)', content)]
        index.append({'path': name, 'lines': len(lines), 'sha256': digest, 'symbols': symbols})
        language = {'.py': 'python', '.dart': 'dart', '.xml': 'xml', '.kt': 'kotlin', '.kts': 'kotlin'}.get(path.suffix, 'text')
        sections.extend([f'## {name}', f'{len(lines)} lines. SHA-256: `{digest}`.',
                         'Symbols: ' + ('; '.join(symbols) or 'Configuration/resource file.'),
                         f'```{language}\n' + '\n'.join(f'{i:04d} | {line}' for i, line in enumerate(lines, 1)) + '\n```'])
    tests = sorted(p for p in paths if '/test' in p and p.endswith(('.py', '.dart')))
    sections += ['## Test-file inventory', '\n'.join(f'- `{p}`' for p in tests)]
    (OUT / 'ClaimLens_Source_Reference.md').write_text('\n\n'.join(sections) + '\n', encoding='utf-8')
    (OUT / 'ClaimLens_Source_Index.json').write_text(json.dumps(index, indent=2), encoding='utf-8')
    handbook = OUT / 'ClaimLens_Project_Portfolio.md'
    base = handbook.read_text(encoding='utf-8').split('<!-- GENERATED APPENDICES -->')[0].rstrip()
    appendix = ['<!-- GENERATED APPENDICES -->', '### 31.1 API endpoint catalogue',
                'Generated from the FastAPI OpenAPI schema. Security and role checks must also be read in the routers and dependencies.',
                '| Method | Path | Operation |', '|---|---|---|']
    for path, operations in schema['paths'].items():
        for method, spec in operations.items():
            if method in {'get', 'post', 'put', 'patch', 'delete'}:
                appendix.append(f"| {method.upper()} | `{path}` | {spec.get('summary', '')} |")
    appendix += ['### 31.2 API model inventory', ', '.join(f'`{x}`' for x in sorted(schema.get('components', {}).get('schemas', {}))),
                '### 31.3 Dependency manifests']
    for name in ['mobile/claimlens_mobile/pubspec.yaml', 'services/api/requirements.txt']:
        appendix += [f'#### {name}', '```text\n' + (ROOT / name).read_text(encoding='utf-8') + '\n```']
    appendix += ['### 31.4 Source-file map', '| File | Lines |', '|---|---|']
    appendix += [f"| `{x['path']}` | {x['lines']} |" for x in index]
    handbook.write_text(base + '\n\n' + '\n\n'.join(appendix) + '\n', encoding='utf-8')
    make_word(handbook)
    downloads = Path.home() / 'Downloads'
    bundle = downloads / 'ClaimLens_Dissertation_Portfolio.zip'
    with zipfile.ZipFile(bundle, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in OUT.rglob('*'):
            if path.is_file():
                archive.write(path, str(Path('ClaimLens_Dissertation_Portfolio') / path.relative_to(OUT)))
    print(json.dumps({'source_files': len(index), 'source_lines': sum(x['lines'] for x in index),
                      'endpoints': sum(len([m for m in ops if m in {'get','post','put','patch','delete'}]) for ops in schema['paths'].values()),
                      'bundle': str(bundle)}))


def make_word(source):
    from docx import Document
    from docx.shared import Inches, Pt, RGBColor
    document = Document()
    section = document.sections[0]
    section.top_margin = section.bottom_margin = Inches(.7)
    normal = document.styles['Normal']
    normal.font.name = 'Calibri'
    normal.font.size = Pt(10)
    for name in ['Title', 'Heading 1', 'Heading 2', 'Heading 3']:
        document.styles[name].font.color.rgb = RGBColor.from_string('006D77')
    section.header.paragraphs[0].text = 'ClaimLens | Dissertation portfolio and technical handbook'
    section.footer.paragraphs[0].text = 'Implementation reference — verify academic claims and add your own evaluation results.'
    code = False
    table = None
    for line in source.read_text(encoding='utf-8').splitlines():
        if line.startswith('```'):
            code = not code
            table = None
            continue
        if line.startswith('<!--'):
            continue
        if code:
            paragraph = document.add_paragraph(line)
            for run in paragraph.runs:
                run.font.name = 'Consolas'
                run.font.size = Pt(8)
            continue
        if line.startswith('|'):
            values = [x.strip().replace('`', '') for x in line.strip('|').split('|')]
            if all(re.fullmatch(r'[:\- ]+', x) for x in values):
                continue
            if table is None or len(table.columns) != len(values):
                table = document.add_table(rows=0, cols=len(values))
                table.style = 'Light Shading Accent 1'
            cells = table.add_row().cells
            for cell, value in zip(cells, values):
                cell.text = value
            continue
        if not line.strip():
            continue
        table = None
        clean = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1 (\2)', line).replace('**', '').replace('`', '')
        match = re.match(r'^(#{1,6}) (.*)', clean)
        if match:
            document.add_heading(match.group(2), level=min(len(match.group(1))-1, 3))
        elif clean.startswith('- '):
            document.add_paragraph(clean[2:], style='List Bullet')
        else:
            document.add_paragraph(clean)
    target = source.with_suffix('.docx')
    document.save(target)
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None


if __name__ == '__main__':
    main()
