#!/usr/bin/env python3
"""Convert the raw Science Bowl Python list into a Flutter JSON asset."""

from __future__ import annotations

import ast
import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RAW_PATH = ROOT / "data" / "raw" / "questions.py"
OUTPUT_PATH = ROOT / "assets" / "questions" / "questions.json"

KNOWN_CATEGORIES = (
    "Earth and Space",
    "Physical Science",
    "General Science",
    "Earth Science",
    "Life Science",
    "Energy",
    "Math",
)

TYPE_LABELS = {
    "Multiple Choice": "multipleChoice",
    "Short Answer": "shortAnswer",
}

CHOICE_RE = re.compile(r"(?:^|\s)([WXYZ])\)\s*")


def load_rows() -> list[list[str]]:
    module = ast.parse(RAW_PATH.read_text(encoding="utf-8"))
    if not module.body or not isinstance(module.body[0], ast.Assign):
        raise ValueError("Expected questions.py to start with an assignment.")

    rows = ast.literal_eval(module.body[0].value)
    if not isinstance(rows, list):
        raise ValueError("Expected the assigned value to be a list.")

    return rows


def normalize_category(value: str) -> str:
    value = value.strip()
    for category in KNOWN_CATEGORIES:
        if value.upper() == category.upper():
            return category
    return value.title() if value and value != "Error" else "General Science"


def repair_error_prefix(
    category: str,
    question_type: str,
    prompt: str,
) -> tuple[str, str, str]:
    cleaned = prompt.strip()
    cleaned = re.sub(r"^\)+\s*", "", cleaned)

    if cleaned.upper().startswith("HYSICAL SCIENCE"):
        cleaned = "P" + cleaned

    upper = cleaned.upper()
    for known_category in sorted(KNOWN_CATEGORIES, key=len, reverse=True):
        prefix = known_category.upper()
        if not upper.startswith(prefix):
            continue

        category = known_category
        cleaned = cleaned[len(known_category) :].strip()
        upper = cleaned.upper()
        for display_type in TYPE_LABELS:
            if upper.startswith(display_type.upper()):
                question_type = display_type
                cleaned = cleaned[len(display_type) :].strip()
                break
        break

    return category, question_type, cleaned


def infer_type(question_type: str, prompt: str, answer: str) -> str:
    if question_type in TYPE_LABELS:
        return question_type

    answer_starts_with_choice = bool(re.match(r"^[WXYZ]\)", answer.strip(), re.I))
    prompt_has_choices = bool(CHOICE_RE.search(prompt))
    if answer_starts_with_choice or prompt_has_choices:
        return "Multiple Choice"

    return "Short Answer"


def split_choices(prompt: str) -> tuple[str, list[dict[str, str]]]:
    matches = list(CHOICE_RE.finditer(prompt))
    if not matches:
        return prompt.strip(), []

    question_text = prompt[: matches[0].start()].strip().rstrip(":").strip()
    choices = []

    for index, match in enumerate(matches):
        next_start = matches[index + 1].start() if index + 1 < len(matches) else len(prompt)
        choices.append(
            {
                "label": match.group(1).upper(),
                "text": prompt[match.end() : next_start].strip(),
            }
        )

    return question_text, choices


def answer_label(answer: str) -> str | None:
    match = re.match(r"^([WXYZ])\)", answer.strip(), re.I)
    return match.group(1).upper() if match else None


def convert_row(index: int, row: list[str]) -> dict[str, object]:
    if len(row) != 6:
        raise ValueError(f"Row {index} has {len(row)} fields instead of 6.")

    set_id, question_number, category, question_type, prompt, answer = [
        str(item).strip() for item in row
    ]

    if category == "Error" or question_type == "Error":
        category, question_type, prompt = repair_error_prefix(category, question_type, prompt)

    category = normalize_category(category)
    question_type = infer_type(question_type, prompt, answer)
    prompt, choices = split_choices(prompt) if question_type == "Multiple Choice" else (prompt, [])

    return {
        "id": f"q-{index + 1:04d}",
        "setId": set_id,
        "questionNumber": question_number,
        "category": category,
        "type": TYPE_LABELS[question_type],
        "question": prompt,
        "answer": answer,
        "answerLabel": answer_label(answer),
        "choices": choices,
    }


def main() -> None:
    rows = load_rows()
    questions = [convert_row(index, row) for index, row in enumerate(rows)]

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    categories = Counter(question["category"] for question in questions)
    types = Counter(question["type"] for question in questions)
    print(f"Wrote {len(questions)} questions to {OUTPUT_PATH.relative_to(ROOT)}")
    print("Categories:")
    for category, count in sorted(categories.items()):
        print(f"  {category}: {count}")
    print("Types:")
    for question_type, count in sorted(types.items()):
        print(f"  {question_type}: {count}")


if __name__ == "__main__":
    main()
