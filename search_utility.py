import os
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
                
                for query in queries:
                    all_found = True
                    for part in query:
                        if part.lower() not in text_lower:
                            all_found = False
                            break
                    if all_found:
                        matches.append(str(pdf_path))
                        print(f"\n--- MATCH FOUND: {pdf_path.name} ---")
                        print("Filepath:", pdf_path)
                        print("Metadata:", reader.metadata)
                        print("First page text snippet:", reader.pages[0].extract_text()[:1000].replace('\n', ' '))
                        break
        except Exception as e:
            pass
            
if __name__ == "__main__":
    drive_dir = "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João"
    queries = [
        ["Utility-based Regression", "Torgo"],
        ["Utility based Regression", "Torgo"]
    ]
    search_pdfs(drive_dir, queries)
