# ClaimLens dissertation handover

Start with **ClaimLens_Project_Portfolio.docx** (Word) or the equivalent Markdown file. It explains the problem, requirements, architecture, roles, authentication, OCR, workflows, data, security, testing, operation, limitations and suggested dissertation chapters.

For detailed implementation questions, attach **ClaimLens_Source_Reference.md** too. It contains numbered application/API source lines, file hashes and symbol locations. **ClaimLens_Source_Index.json** is the machine-readable file map. **ClaimLens_API_Schema.json** describes the REST interface.

**verification-results.json** records the latest known verification status, including incomplete checks. These files describe a working-tree snapshot; they do not certify a production release. Use your own evaluation dataset, results, screenshots, institutional formatting and academic references in the final dissertation. Fill the academic placeholders in the handbook.

Regenerate from the repository root using the API Python environment:

```powershell
python scripts/build_portfolio.py
```

The generator requires the API dependencies and python-docx. It writes a ZIP to the current user's Downloads folder. It excludes private environment files, Firebase service-account credentials, real uploaded evidence and SDK client configuration from the source appendix. Keep those exclusions when expanding it.

Suggested AI handover: “Read the portfolio first, then consult the numbered source reference and OpenAPI schema. Explain ClaimLens using the actual code. Cite file paths and line numbers. Separate implemented behavior, test evidence, limitations and future work. Do not invent deployment status, OCR accuracy or research findings.”
