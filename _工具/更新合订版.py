"""从独立 Markdown 笔记和实战案例更新连续阅读版；仅使用 Python 标准库。"""

from pathlib import Path
import posixpath
import re


ROOT = Path(__file__).resolve().parent.parent
PREFERRED_ORDER = [
    "一本书读懂财报",
    "聪明的投资者",
    "巴菲特股东信",
    "投资最重要的事",
    "思考，快与慢",
    "学会提问",
    "超级预测",
    "股票大作手回忆录",
    "海龟交易法则",
    "以交易为生",
    "被讨厌的勇气",
    "金钱心理学",
    "小狗钱钱",
    "漫步华尔街",
    "共同基金常识",
    "股市长线法宝",
    "彼得·林奇的成功投资",
    "怎样选择成长股",
    "穷查理宝典",
    "投资中最简单的事",
    "周期",
    "随机漫步的傻瓜",
    "黑天鹅",
    "反脆弱",
    "对赌",
    "噪声",
    "事实",
    "统计陷阱",
    "清醒思考的艺术",
    "影响力",
    "系统之美",
    "战胜华尔街",
    "股市真规则",
    "巴菲特的护城河",
    "投资估价",
    "证券分析",
    "价值投资",
    "安全边际",
    "资本回报",
    "投资者的未来",
    "金融炼金术",
    "富爸爸穷爸爸",
    "邻家的百万富翁",
    "巴比伦最富有的人",
    "金钱与生活",
    "拿铁因素",
    "投资四大支柱",
    "聪明的资产配置",
    "机构投资的创新之路",
    "非理性繁荣",
    "金融的逻辑",
    "经济学原理",
    "牛奶可乐经济学",
    "魔鬼经济学",
    "卧底经济学",
    "置身事内",
    "贫穷的本质",
    "这次不一样",
    "债务危机",
    "逃不开的经济周期",
    "小岛经济学",
    "简单的逻辑学",
    "思辨与立场",
    "超越智商",
    "为什么",
    "模型思维",
    "助推",
    "错误的行为",
    "怪诞行为学",
    "决断力",
    "清单革命",
    "竞争战略",
    "竞争优势",
    "好战略，坏战略",
    "创新者的窘境",
    "从优秀到卓越",
    "国富论",
    "就业、利息和货币通论",
    "资本主义、社会主义与民主",
    "大空头",
    "当音乐停止之后",
    "理性",
    "直觉泵和其他思考工具",
    "科学革命的结构",
    "猜想与反驳",
    "信号与噪声",
    "赢得输家的游戏",
    "财务自由之路",
    "金钱不能买什么",
    "稀缺",
    "金钱的灵魂",
]
LINK = re.compile(r"(!?\[[^\]]*\])\((<[^>]*>|[^)]*)\)")


def book_order(path):
    title = path.parent.name.split(" - ", 1)[0]
    position = PREFERRED_ORDER.index(title) if title in PREFERRED_ORDER else len(PREFERRED_ORDER)
    return position, path.parent.name


def rewrite_link(match, folder):
    label, raw = match.groups()
    target = raw.strip("<>")
    if target.startswith(("http:", "https:", "mailto:", "#")):
        return match.group(0)
    path, separator, anchor = target.partition("#")
    translated = posixpath.normpath(folder + "/" + path)
    if separator:
        translated += "#" + anchor
    return f"{label}(<{translated}>)"


def shift_headings_and_links(text, folder):
    output = []
    fence = None
    for line in text.splitlines():
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            output.append(line)
            continue
        if fence is None:
            if re.match(r"^#{1,5} ", line):
                line = "#" + line
            line = LINK.sub(lambda match: rewrite_link(match, folder), line)
        output.append(line)
    return "\n".join(output)


def main():
    paths = sorted(
        (p for p in ROOT.glob("*/读书笔记.md") if not p.parent.name.startswith("_")),
        key=book_order,
    )
    cases = sorted((ROOT / "实战案例").glob("*.md"))
    lines = [
        "# 全部书籍笔记合订版",
        "",
        f"> 本文件汇集 {len(paths)} 份独立笔记与 {len(cases)} 篇实战案例附录，方便连续阅读。各篇的分析依据、版本和来源保留在原位置。",
        "> 独立笔记与案例原文件是主要维护版本；修改后可运行 `_工具/更新合订版.py` 同步本文件。",
        "",
        "想先建立学习和实践流程，请读[《财商进阶合订本》](财商进阶合订本.md)；"
        "想单独打开一本，请访问[书籍索引](README.md)。",
        "",
        "## 目录",
        "",
    ]
    for number, path in enumerate(paths, 1):
        lines.append(f"{number}. [{path.parent.name}](#book-{number:02d})")
    if cases:
        lines.extend(["", "**实战案例附录**", ""])
        for number, path in enumerate(cases, 1):
            lines.append(f"{number}. [{path.stem}](#case-{number:02d})")
    for number, path in enumerate(paths, 1):
        lines.extend([
            "", "---", "", f'<a id="book-{number:02d}"></a>', "",
            f"[单独打开本篇](<{path.parent.name}/读书笔记.md>)", "",
            shift_headings_and_links(path.read_text(encoding="utf-8"), path.parent.name),
            "",
        ])
    for number, path in enumerate(cases, 1):
        relative = path.relative_to(ROOT).as_posix()
        lines.extend([
            "", "---", "", f'<a id="case-{number:02d}"></a>', "",
            f"[单独打开本案例](<{relative}>)", "",
            shift_headings_and_links(path.read_text(encoding="utf-8"), path.parent.name),
            "",
        ])
    destination = ROOT / "全部书籍笔记合订版.md"
    destination.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    print(f"已汇总 {len(paths)} 份笔记与 {len(cases)} 篇实战案例：{destination}")


if __name__ == "__main__":
    main()
