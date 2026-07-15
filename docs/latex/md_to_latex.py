import os
import re
import pypandoc
import glob

DOCS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
LATEX_DIR = os.path.abspath(os.path.dirname(__file__))
CHAPTERS_DIR = os.path.join(LATEX_DIR, 'chapters')

os.makedirs(CHAPTERS_DIR, exist_ok=True)

# List of files to process
files = [
    'guide/01-big-picture.md',
    'guide/02-directory-structure.md',
    'guide/03-lifecycle.md',
    'guide/04-workflow.md',
    'guide/05-automation.md',
    'guide/06-file-reference.md',
    'guide/07-environments.md',
    'guide/08-git-workflow.md',
    'guide/09-new-experiments.md',
    'guide/10-rules.md',
    'guide/11-troubleshooting.md',
    'methodology.md'
]

def convert_admonitions(markdown_content):
    """Convert > **Note**: or > [!WARNING] to LaTeX environments before pandoc."""
    lines = markdown_content.split('\n')
    out_lines = []
    in_note = False
    in_warn = False
    
    for line in lines:
        if line.startswith('> **Note**') or line.startswith('> [!NOTE]'):
            out_lines.append(r'\begin{noteblock}')
            in_note = True
            text = line.replace('> **Note**:', '').replace('> [!NOTE]', '').strip()
            if text:
                out_lines.append(text)
        elif line.startswith('> **Warning**') or line.startswith('> [!WARNING]'):
            out_lines.append(r'\begin{warningblock}')
            in_warn = True
            text = line.replace('> **Warning**:', '').replace('> [!WARNING]', '').strip()
            if text:
                out_lines.append(text)
        elif (in_note or in_warn) and line.startswith('>'):
            out_lines.append(line[1:].strip())
        elif (in_note or in_warn) and not line.strip():
            # End of blockquote
            if in_note:
                out_lines.append(r'\end{noteblock}')
                in_note = False
            if in_warn:
                out_lines.append(r'\end{warningblock}')
                in_warn = False
            out_lines.append('')
        else:
            if in_note:
                out_lines.append(r'\end{noteblock}')
                in_note = False
            if in_warn:
                out_lines.append(r'\end{warningblock}')
                in_warn = False
            out_lines.append(line)
            
    if in_note:
        out_lines.append(r'\end{noteblock}')
    if in_warn:
        out_lines.append(r'\end{warningblock}')
        
    return '\n'.join(out_lines)

def post_process_latex(latex_content):
    """Convert listings to minted and fix headings."""
    # Convert \section to \section (since we use article, h1 is section, h2 is subsection)
    # Pandoc already does this if we don't use --top-level-division=chapter
    
    # Convert listings to minted
    # \begin{lstlisting}[language=bash]
    latex_content = re.sub(r'\\begin\{lstlisting\}\[language=(.*?)\]', r'\\begin{minted}{\1}', latex_content)
    # \begin{lstlisting} (no language)
    latex_content = re.sub(r'\\begin\{lstlisting\}', r'\\begin{minted}{text}', latex_content)
    # \end{lstlisting}
    latex_content = re.sub(r'\\end\{lstlisting\}', r'\\end{minted}', latex_content)
    
    # Emojis (using parentheses to avoid LaTeX thinking it's an optional argument like \\[...])
    emojis = {
        '📁': '(DIR)',
        '✅': '(OK)',
        '⚪': '(WAITING)',
        '🔵': '(RUNNING)',
        '🟡': '(REVIEW)',
        '🟢': '(DONE)',
        '🔴': '(ERROR)',
        '⚠️': '(WARN)',
        '⚙️': '(GEAR)',
        '📊': '(PLOT)',
        '📝': '(NOTE)',
        '🔍': '(SEARCH)',
        '🚀': '(LAUNCH)',
        '💡': '(IDEA)',
        '🗂️': '(INDEX)',
        '→': '->'
    }
    for e, rep in emojis.items():
        latex_content = latex_content.replace(e, rep)
    
    # Fix tightlist
    if 'tightlist' not in latex_content:
        latex_content = latex_content.replace('\\begin{itemize}', '\\begin{itemize}\\tightlist')
        latex_content = latex_content.replace('\\begin{enumerate}', '\\begin{enumerate}\\tightlist')
        
    return latex_content

for md_file in files:
    src_path = os.path.join(DOCS_DIR, md_file)
    if not os.path.exists(src_path):
        print(f"Skipping {src_path} (not found)")
        continue
        
    # 1. Read and pre-process markdown
    with open(src_path, 'r', encoding='utf-8') as f:
        md_text = f.read()
    
    md_text = convert_admonitions(md_text)
    
    # Save temporary md
    tmp_md = os.path.join(LATEX_DIR, 'tmp.md')
    with open(tmp_md, 'w', encoding='utf-8') as f:
        f.write(md_text)
        
    # 2. Run pandoc
    basename = os.path.basename(md_file).replace('.md', '.tex')
    dst_path = os.path.join(CHAPTERS_DIR, basename)
    
    pypandoc.convert_file(
        tmp_md,
        'latex',
        outputfile=dst_path,
        extra_args=['--listings']
    )
    
    # 3. Post-process latex
    with open(dst_path, 'r', encoding='utf-8') as f:
        tex_text = f.read()
        
    tex_text = post_process_latex(tex_text)
    
    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(tex_text)
        
    print(f"Converted {md_file} -> {dst_path}")

if os.path.exists(tmp_md):
    os.remove(tmp_md)
print("All done!")
