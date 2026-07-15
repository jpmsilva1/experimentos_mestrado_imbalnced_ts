"""
md_to_latex.py
Converts all guide Markdown files to clean LaTeX chapters.
Run from the repo root: python3 docs/latex/md_to_latex.py
"""
import os
import re
import pypandoc

DOCS_DIR    = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
LATEX_DIR   = os.path.abspath(os.path.dirname(__file__))
CHAPTERS_DIR = os.path.join(LATEX_DIR, 'chapters')

os.makedirs(CHAPTERS_DIR, exist_ok=True)

# ── File list ──────────────────────────────────────────────────────────────────
FILES = [
    ('guide/01-big-picture.md',        'section'),
    ('guide/02-directory-structure.md','section'),
    ('guide/03-lifecycle.md',          'section'),
    ('guide/04-workflow.md',           'section'),
    ('guide/05-automation.md',         'section'),
    ('guide/06-file-reference.md',     'section'),
    ('guide/07-environments.md',       'section'),
    ('guide/08-git-workflow.md',       'section'),
    ('guide/09-new-experiments.md',    'section'),
    ('guide/10-rules.md',              'section'),
    ('guide/11-troubleshooting.md',    'section'),
    ('methodology.md',                 'section'),
]

# ── Emoji / special char replacement map ──────────────────────────────────────
# IMPORTANT: these replacements are applied to raw Markdown BEFORE pandoc,
# which means they will appear verbatim inside minted/code blocks.
# Use ONLY plain text here — never LaTeX commands.
EMOJI_MAP = {
    '→': '->',
    '←': '<-',
    '⇒': '=>',
    '📁': '[DIR]',
    '✅': '[OK]',
    '❌': '[FAIL]',
    '⚪': '[WAITING]',
    '🔵': '[RUNNING]',
    '🟡': '[REVIEW]',
    '🟢': '[DONE]',
    '🔴': '[ERROR]',
    '⚠':  '[WARN]',
    '⚙':  '[GEAR]',
    '📊': '[PLOT]',
    '📝': '[NOTE]',
    '🔍': '[SEARCH]',
    '🚀': '[LAUNCH]',
    '💡': '[IDEA]',
    '🗂':  '[INDEX]',
    '🏠': '[HOME]',
    '📜': '[DOC]',
    '🧪': '[EXP]',
    '📋': '[LIST]',
    '🔗': '[LINK]',
    '📚': '[BOOK]',
    # Variation selectors & ZWJ (invisible chars that break LaTeX)
    '\ufe0f': '',
    '\u200d': '',
}


def apply_emoji_map(text: str) -> str:
    """Replace all known emoji/special chars. Applied to raw Markdown BEFORE pandoc."""
    for char, replacement in EMOJI_MAP.items():
        text = text.replace(char, replacement)
    return text


def pre_process_markdown(md_text: str) -> str:
    """
    Pre-process Markdown before handing to pandoc.
    - Replaces emoji
    - Removes inline ---/*** horizontal rules (they produce ugly LaTeX)
    - Converts > [!NOTE] / > **Note**: admonitions into a placeholder we can
      then turn into LaTeX environments in post-process
    """
    # Replace emoji
    md_text = apply_emoji_map(md_text)

    # Remove standalone horizontal rules --- or ***
    md_text = re.sub(r'^\s*[-*]{3,}\s*$', '', md_text, flags=re.MULTILINE)

    # Collapse runs of blank lines to at most two
    md_text = re.sub(r'\n{3,}', '\n\n', md_text)

    return md_text


def escape_for_texttt(text: str) -> str:
    """Escape LaTeX special chars so they can appear inside \\texttt{}."""
    # Order matters — escape backslash first
    text = text.replace('\\', r'\textbackslash{}')
    text = text.replace('{',  r'\{')
    text = text.replace('}',  r'\}')
    text = text.replace('_',  r'\_')
    text = text.replace('^',  r'\^{}')
    text = text.replace('~',  r'\~{}')
    text = text.replace('#',  r'\#')
    text = text.replace('$',  r'\$')
    text = text.replace('%',  r'\%')
    text = text.replace('&',  r'\&')
    return text


def replace_inline_code(latex_text: str) -> str:
    """
    Replace \\passthrough{\\lstinline!...!} (and variants) with
    \\texttt{...} where the content is properly LaTeX-escaped.
    This avoids overflow because \\texttt can break at word boundaries.
    """
    # Pattern: \passthrough{\lstinline!CONTENT!}
    # The delimiter after \lstinline can be any non-alphanumeric char
    pattern = re.compile(
        r'\\passthrough\{\\lstinline(.)(.*?)\1\}',
        re.DOTALL
    )
    def replacer(m):
        content = m.group(2)
        # Apply emoji map again in case it slipped through
        content = apply_emoji_map(content)
        escaped = escape_for_texttt(content)
        return r'\texttt{' + escaped + r'}'

    return pattern.sub(replacer, latex_text)


def fix_headings(latex_text: str) -> str:
    """
    Pandoc with --top-level-division=section maps:
      # h1  -> \section
      ## h2 -> \subsection
    That is correct. No changes needed here.
    """
    return latex_text


def fix_tables(latex_text: str) -> str:
    """
    Pandoc generates longtable with \real{} column widths.
    Add \\small inside longtable to prevent overflow.
    Also wrap the whole longtable in a group so font size is localised.
    """
    # Wrap longtable blocks to use \small font size
    latex_text = re.sub(
        r'(\\begin\{longtable\})',
        r'\\small\n\1',
        latex_text
    )
    return latex_text


def fix_horizontal_rules(latex_text: str) -> str:
    """
    Remove the \\begin{center}\\rule{...}\\end{center} separators pandoc emits
    for --- in markdown — they look bad as section separators in article style.
    """
    latex_text = re.sub(
        r'\\begin\{center\}\\rule\{[^}]+\}\{[^}]+\}\\end\{center\}',
        '',
        latex_text
    )
    return latex_text


def fix_blockquotes(latex_text: str) -> str:
    """
    Pandoc wraps > blockquotes in \begin{quote}...\end{quote}.
    Replace with our styled noteblock/warningblock if the content starts
    with (WARN) or (IMPORTANT), otherwise use the default quote.
    """
    def quote_replacer(m):
        content = m.group(1).strip()
        if content.startswith('(WARN)') or content.startswith('Warning'):
            inner = content.removeprefix('(WARN)').strip()
            return f'\\begin{{warningblock}}\n{inner}\n\\end{{warningblock}}'
        elif content.startswith('(NOTE)') or content.startswith('Note'):
            inner = content.removeprefix('(NOTE)').strip()
            return f'\\begin{{noteblock}}\n{inner}\n\\end{{noteblock}}'
        else:
            return f'\\begin{{quote}}\n\\small {content}\n\\end{{quote}}'

    latex_text = re.sub(
        r'\\begin\{quote\}(.*?)\\end\{quote\}',
        quote_replacer,
        latex_text,
        flags=re.DOTALL
    )
    return latex_text


def convert_lstlisting_to_minted(latex_text: str) -> str:
    """
    Convert \\begin{lstlisting}[language=X]...\\end{lstlisting}
    to \\begin{minted}{x}...\\end{minted} for colorful Pygments highlighting.
    Falls back to 'text' if no language is specified.
    """
    # Map listing language names to Pygments lexer names
    lang_map = {
        'bash': 'bash', 'sh': 'bash', 'shell': 'bash',
        'python': 'python', 'python3': 'python',
        'yaml': 'yaml', 'json': 'json',
        'r': 'r', 'R': 'r',
        'text': 'text', '': 'text',
    }

    def replacer(m):
        lang_raw = (m.group(1) or '').strip().lower()
        lang = lang_map.get(lang_raw, lang_raw if lang_raw else 'text')
        body = m.group(2)
        # Strip ANY LaTeX commands that leaked into verbatim blocks.
        # e.g. \texttt{[DIR]} -> [DIR],  \textbf{[OK]} -> [OK]
        body = re.sub(r'\\[a-zA-Z]+\{([^}]*)\}', r'\1', body)
        # Strip bare LaTeX commands with no argument
        body = re.sub(r'\\[a-zA-Z]+\b', '', body)
        return f'\\begin{{minted}}{{{lang}}}\n{body}\\end{{minted}}'

    # With language argument: \begin{lstlisting}[language=bash]
    latex_text = re.sub(
        r'\\begin\{lstlisting\}\[language=([^\]]*)\]\n?(.*?)\\end\{lstlisting\}',
        replacer,
        latex_text,
        flags=re.DOTALL
    )
    # Without language argument: \begin{lstlisting}
    latex_text = re.sub(
        r'\\begin\{lstlisting\}\n?(.*?)\\end\{lstlisting\}',
        lambda m: f'\\begin{{minted}}{{text}}\n{m.group(1)}\\end{{minted}}',
        latex_text,
        flags=re.DOTALL
    )
    return latex_text


def post_process(latex_text: str) -> str:
    """Apply all post-processing steps in order."""
    latex_text = replace_inline_code(latex_text)
    latex_text = convert_lstlisting_to_minted(latex_text)   # ← key: colorful code blocks
    latex_text = fix_headings(latex_text)
    latex_text = fix_tables(latex_text)
    latex_text = fix_horizontal_rules(latex_text)
    latex_text = fix_blockquotes(latex_text)
    # Apply emoji map one final time (catches anything that went through pandoc)
    latex_text = apply_emoji_map(latex_text)
    return latex_text


# ── Main conversion loop ───────────────────────────────────────────────────────
tmp_md = os.path.join(LATEX_DIR, '_tmp.md')

for md_file, _ in FILES:
    src_path = os.path.join(DOCS_DIR, md_file)
    if not os.path.exists(src_path):
        print(f'  SKIP  {md_file} (not found)')
        continue

    with open(src_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    md_text = pre_process_markdown(md_text)

    with open(tmp_md, 'w', encoding='utf-8') as f:
        f.write(md_text)

    basename  = os.path.basename(md_file).replace('.md', '.tex')
    dst_path  = os.path.join(CHAPTERS_DIR, basename)

    pypandoc.convert_file(
        tmp_md,
        'latex',
        outputfile=dst_path,
        extra_args=[
            '--syntax-highlighting=idiomatic',  # syntax highlighting for inline code
            '--top-level-division=section',     # ## -> \subsection, # -> \section
        ]
    )

    with open(dst_path, 'r', encoding='utf-8') as f:
        tex = f.read()

    tex = post_process(tex)

    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(tex)

    print(f'  OK    {md_file} -> {basename}')

if os.path.exists(tmp_md):
    os.remove(tmp_md)

print('\nAll chapters converted successfully.')
