import os
from pathlib import Path

drive_dir = "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João"
count = 0
for p in Path(drive_dir).rglob("*.pdf"):
    print(p.name)
    count += 1
    if count >= 10:
        break
