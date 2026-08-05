import os
import sys
import pypdf
from pathlib import Path

def search_pdfs(directory, queries):
    directory = Path(directory)
    matches = []
    
    for pdf_path in directory.rglob('*.pdf'):
        try:
            with open(pdf_path, 'rb') as f:
                reader = pypdf.PdfReader(f)
                text = ""
                for page in reader.pages:
                    extracted = page.extract_text()
                    if extracted:
                        text += extracted + "\n"
                
                text_lower = text.lower()
                
                # Check if all parts of a query are present
                for query in queries:
                    all_found = True
                    for part in query:
                        if part.lower() not in text_lower:
                            all_found = False
                            break
                    if all_found:
                        matches.append(str(pdf_path))
                        print(f"Match found in: {pdf_path.name}")
                        break
        except Exception as e:
            print(f"Error reading {pdf_path.name}: {e}")
            
    print("\n--- RESULTS ---")
    for match in matches:
        print(match)

if __name__ == "__main__":
    drive_dir = "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João"
    # we want to match something like "Moniz, N., Branco, P., & Torgo, L. (2017). Resampling Strategies for Imbalanced Time Series Forecasting"
    # or just the title "Resampling Strategies for Imbalanced Time Series Forecasting"
    # Some PDFs might have it split by newline, so searching just by the title which is quite unique is better.
    # We can use multiple potential patterns
    queries = [
        ["Resampling Strategies for Imbalanced Time Series Forecasting"],
        ["Moniz", "Resampling Strategies", "Imbalanced Time Series Forecasting"]
    ]
    search_pdfs(drive_dir, queries)
