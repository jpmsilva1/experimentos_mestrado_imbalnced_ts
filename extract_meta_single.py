import pypdf

pdf = "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/A cost-sensitive active learning algorithm.pdf"
try:
    reader = pypdf.PdfReader(pdf)
    meta = reader.metadata
    print("Metadata:", meta)
    text = reader.pages[0].extract_text()
    print("First page text snippet:", text[:1000].replace('\n', ' '))
except Exception as e:
    print("Error:", e)
