"""检查独立笔记、索引与连续阅读版的结构和本地链接。"""
from pathlib import Path
from urllib.parse import unquote
import argparse
import re

ROOT = Path(__file__).resolve().parent.parent
LINK = re.compile(r"!?\[[^\]]*\]\((<[^>]*>|[^)]*)\)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected", type=int)
    args = parser.parse_args()
    notes = sorted(p for p in ROOT.glob("*/读书笔记.md") if not p.parent.name.startswith("_"))
    errors = []
    if args.expected is not None and len(notes) != args.expected:
        errors.append(f"笔记数 {len(notes)} 不等于预期 {args.expected}")
    titles = [p.parent.name.split(" - ", 1)[0] for p in notes]
    if len(titles) != len(set(titles)):
        errors.append("存在重复书名，请核对版本是否确有必要分列")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    points = figures = 0
    files = notes + [ROOT / "README.md", ROOT / "财商进阶合订本.md", ROOT / "全部书籍笔记合订版.md"]
    files += sorted((ROOT / "实战案例").glob("*.md"))
    for path in files:
        content = path.read_text(encoding="utf-8")
        relative = path.relative_to(ROOT).as_posix()
        if "\ufffd" in content:
            errors.append(f"{relative}: 存在 Unicode 替换字符")
        if path in notes:
            if relative not in readme:
                errors.append(f"索引遗漏: {relative}")
            numbers = [int(x) for x in re.findall(r"^###\s+(\d+)[.．、｜]", content, re.M)]
            if numbers and numbers != list(range(1, len(numbers) + 1)):
                errors.append(f"{relative}: 知识点编号不连续 {numbers}")
            points += len(numbers)
            figures += len(re.findall(r"^```mermaid\s*$", content, re.M))
        fence = None
        for number, line in enumerate(content.splitlines(), 1):
            marker = re.match(r"^\s*(`{3,}|~{3,})", line)
            if marker:
                token = marker.group(1)
                if fence is None:
                    fence = token
                elif token[0] == fence[0] and len(token) >= len(fence):
                    fence = None
                continue
            if fence is not None:
                continue
            for match in LINK.finditer(line):
                target = match.group(1).strip("<>")
                if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target) or target.startswith("#"):
                    continue
                target = unquote(target.partition("#")[0])
                if target and not (path.parent / target).resolve().exists():
                    errors.append(f"{relative}:{number}: 本地链接不存在 {target}")
        if fence:
            errors.append(f"{relative}: 代码围栏未闭合")
    combined = (ROOT / "全部书籍笔记合订版.md").read_text(encoding="utf-8")
    anchors = re.findall(r'<a id="book-(\d+)"></a>', combined)
    if [int(x) for x in anchors] != list(range(1, len(notes) + 1)):
        errors.append("连续阅读版的书籍锚点数量或顺序错误")
    print(f"笔记 {len(notes)} 本；编号知识点 {points}；Mermaid {figures} 幅；检查文件 {len(files)} 个")
    if errors:
        for error in errors:
            print(error)
        raise SystemExit(1)
    print("通过：UTF-8、编号、围栏、本地链接、索引覆盖、连续阅读版锚点")


if __name__ == "__main__":
    main()
