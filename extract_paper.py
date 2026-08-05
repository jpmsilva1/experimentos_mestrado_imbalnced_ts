import sys
import pypdf
from pathlib import Path

pdf_path = "/Users/joaopms/Desktop/Papers Mestrado - João copy/A Survey of Predictive Modeling on Imbalanced Domains.pdf"
output_path = "/Users/joaopms/Documents/Projeto_Mestrado/scratch_paper_text.md"

try:
    with open(pdf_path, 'rb') as f:
        reader = pypdf.PdfReader(f)
        with open(output_path, 'w', encoding='utf-8') as out:
            for i, page in enumerate(reader.pages):
                out.write(f"\n--- PAGE {i+1} ---\n")
                extracted = page.extract_text()
                if extracted:
                    out.write(extracted + "\n")
    print(f"Extraction successful: {output_path}")
except Exception as e:
    print(f"Error: {e}")
