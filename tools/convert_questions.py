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
REPORT_PATH = ROOT / "data" / "cleaned" / "question_cleanup_report.md"

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

MANUAL_FIXES: dict[int, dict[str, str]] = {
    852: {
        "answer": "14.1 (Solution: c = a√2 = 10√2 ≈ 14.1 m)",
    },
    947: {
        "answer": "SHORTER LEG = 6; LONGER LEG = 6√3",
    },
    951: {
        "prompt": (
            "Add and simplify the following 2 polynomials, giving your answer in "
            "standard form: (9x^3 + 6x^2 + 10x) + (-3x^3 - 10x^2 + 9x)"
        ),
        "answer": "6x^3 - 4x^2 + 19x",
    },
    961: {
        "prompt": (
            "If k is an integer greater than 1, which of the following is greater "
            "than 1: W) -(-k)^3 X) -(k)^3 Y) (-k)^(-1/3) Z) -|k|^3"
        ),
        "answer": "W) -(-k)^3",
    },
    966: {
        "prompt": (
            "Which of the following is equivalent to the radical expression "
            "√(18^18): W) 3^3 X) 9^9 Y) 18^3 Z) 18^9"
        ),
        "answer": "Z) 18^9",
    },
    971: {
        "prompt": "Factor the following polynomial over the integers: 49x^2 - 64",
    },
    1024: {
        "prompt": "Evaluate the following radical expression: -√(√16).",
    },
    1038: {
        "prompt": "What is the degree of the following polynomial: 7x^4y - 5x^3y^3 + 3xy^3 - 4",
    },
    1052: {
        "prompt": "Provide the prime factors over the integers for the following expression: x^3 + 8",
        "answer": "(x + 2) and (x^2 - 2x + 4) (DO NOT ACCEPT (x + 2) times (x^2 - 2x + 4))",
    },
    355: {
        "prompt": "The graph of the equation 2x + y = 4 is a: W) straight line X) parabola Y) ellipse Z) circle",
    },
    677: {
        "prompt": "Which of the following is a binomial? W) x^2/2 X) x^2 + 5x - 2 Y) π Z) x - 2",
        "answer": "Z) x - 2",
    },
    1067: {
        "prompt": (
            "Which of the following is the equation of a parabola whose graph "
            "opens downward: W) y = -x^2 X) y = x^3 Y) y = x^2 + 2 Z) y = x^2 - 2"
        ),
        "answer": "W) y = -x^2",
    },
    1112: {
        "prompt": (
            "Simplify: (2a + 2b + 2c) / 4. W) abc/2 X) (a + b + c)/2 "
            "Y) 2(abc)/2 Z) 2(a + b + c)"
        ),
        "answer": "X) (a + b + c)/2",
    },
    1139: {
        "prompt": (
            "In the Pythagorean theorem, a^2 + b^2 = c^2. If all side lengths "
            "are smaller than 1 unit long, which of the following is largest? "
            "W) a^2 X) b^2 Y) c^2 Z) c"
        ),
    },
    1170: {
        "prompt": (
            "What is the approximate minimum temperature difference in degrees Celsius "
            "required between deep and shallow waters for an Ocean Thermal Energy "
            "Conversion (OTEC) system to be commercially viable? W) 5 X) 10 Y) 20 Z) 50"
        ),
        "answer": "Y) 20",
    },
    1186: {
        "answer": "4πr^2",
    },
    1201: {
        "prompt": "Express in decimal form: 0.99 - 3/4. W) 0.24 X) 0.75 Y) 0.9825 Z) 0.9975",
    },
    1014: {
        "prompt": (
            "Which of the following equations has a graph that is a circle? "
            "W) x^2 + y^2 = 25 X) 4y = 3x + 2 Y) y = x^2 Z) x - 3 = 0"
        ),
        "answer": "W) x^2 + y^2 = 25",
    },
    1009: {
        "prompt": "Solve the following radical equation for x, when x is a real number: √(x - 2) = 4.",
    },
    1048: {
        "prompt": (
            "If the fourth term in the binomial expansion of (x + y)^7 is "
            "35x^4y^3, what is the 5th term?"
        ),
        "answer": "35x^3y^4 (ACCEPT: 35y^4x^3)",
    },
    1244: {
        "prompt": "Simplify: 1/3 ÷ 1/6",
    },
    1220: {
        "prompt": (
            "If a 4-inch plant grows at the rate of 1/4 inch per day, what will "
            "its height be in 27 days? W) 6 3/4 inches X) 7 inches "
            "Y) 10 3/4 inches Z) 11 inches"
        ),
        "answer": "Y) 10 3/4 INCHES",
    },
    1254: {
        "answer": "9.3 × 10^7",
    },
    1328: {
        "prompt": "Expressing your answer in exponential form, simplify: (8^5)(8^5).",
        "answer": "8^10",
    },
    1365: {
        "prompt": "Solve for a: (a - 2) / 9 = 2/3",
    },
    1382: {
        "prompt": "Simplify y^2 · y^-3.",
        "answer": "y^-1 (ACCEPT: 1/y)",
    },
    1385: {
        "prompt": (
            "Which of the following values is smallest? W) 200 X) (-16)^2 "
            "Y) 14^2 Z) (120/8)^2"
        ),
        "answer": "Y) 14^2",
    },
    1389: {
        "prompt": "Solve for x in simplest form: x^2 = 50.",
        "answer": "5√2, -5√2",
    },
    1402: {
        "prompt": (
            "Which of the following can be equal to positive 4? W) |-3| × |1| "
            "X) 2^3 Y) √(-16) Z) √(4^2)"
        ),
        "answer": "Z) √(4^2)",
    },
    1424: {
        "prompt": (
            "Which of the following is a polynomial? W) (a^2 - 4)/(a + 3) "
            "X) 3a^2 - a^-2 + 1 Y) 15a^2 - a^1.5 - 3 Z) a^3"
        ),
        "answer": "Z) a^3",
    },
    1466: {
        "prompt": "What is the degree of the polynomial 7x^2y^4 + 6x + 7y + 10?",
    },
    1463: {
        "prompt": (
            "Which of the following values is smallest? W) 4! X) 5^2 "
            "Y) |√100| × 4 Z) |√625|"
        ),
        "answer": "W) 4!",
    },
    1497: {
        "prompt": (
            "Which of the following is true about the function 4y = x^3 + 5x + 6? "
            "W) The function is odd X) The function is even Y) The function is positive "
            "Z) The function is neither odd nor even"
        ),
    },
    1519: {
        "prompt": "Identify the real zeros of the function f(x) = √(x^2 - 4).",
    },
    1529: {
        "prompt": (
            "Which of the following is perpendicular to the line y = -2x + 6? "
            "W) 2y = x + 4 X) x + 2y = 4 Y) y = 2x - 6 Z) y = -1/2x - 6"
        ),
    },
    1599: {
        "prompt": "Which of the following does NOT represent a function? W) x = 4 X) y = 4 Y) y = x^2 Z) y = 2x - 8",
    },
    1654: {
        "prompt": (
            "Which of the following adjectives describes the function: "
            "y = 1/(3 - x^2)? W) Even X) Odd Y) One-to-one Z) Polynomial"
        ),
    },
    1644: {
        "prompt": "Evaluate the complex expression (3i)^2.",
    },
    1714: {
        "prompt": "Simplify 12 + (√25 - √16)^2.",
    },
    1734: {
        "prompt": (
            "Which of the following inequalities has a finite solution set over "
            "the integers? W) x^2 + 5x + 6 > 0 X) |x + 2| > 4 "
            "Y) 9x - 7 < 3x + 14 Z) x^2 - 4x + 3 < 0"
        ),
        "answer": "Z) x^2 - 4x + 3 < 0",
    },
    1795: {
        "prompt": (
            "The equation x^2 - 3y^2 + 2x - 4y - 8 = 0 graphs as which of the "
            "following conic sections? W) Hyperbola X) Ellipse Y) Parabola Z) Circle"
        ),
    },
    1833: {
        "prompt": (
            "If f(x) = 1/x, then f^-1(x) equals which of the following? "
            "W) x - 1 X) x Y) 1/x^2 Z) 1/x"
        ),
        "answer": "Z) 1/x",
    },
    1879: {
        "prompt": (
            "For what real values of x is the function √(x^2 - 6x - 40) defined? "
            "W) -10 < x < 4 X) -4 < x < 10 "
            "Y) All x that do not lie in the closed interval from -10 to 4 "
            "Z) All x that do not lie in the open interval -4 to 10"
        ),
    },
    1927: {
        "prompt": "When 10^-4 is written in decimal form, how many zeroes are to the right of the decimal?",
    },
    1967: {
        "prompt": "Evaluate (12y)/(5x) when y = 2 and x = 0.",
    },
    2014: {
        "prompt": (
            "The equation x^2/4 + y^2/9 = 1 has a graph that is an example of "
            "which of the following shapes? W) Parabola X) Ellipse Y) Circle Z) Torus"
        ),
    },
    2020: {
        "prompt": (
            "Which of the following is the smallest integer greater than 101^(1/2)? "
            "W) 9 X) 10 Y) 11 Z) 12"
        ),
    },
    2075: {
        "prompt": "Find the value of c that completes the square of r^2 + 32r + c.",
    },
    2039: {
        "prompt": (
            "If you were to graph a line for each of the following equations, "
            "which would NOT intersect the origin? W) y = (1/3)x X) y = 4x "
            "Y) x = 4y Z) x = 5"
        ),
    },
    2102: {
        "prompt": "Find g(1) when g(a) = 3^(3a - 2).",
    },
    2108: {
        "prompt": "What is the determinant of the 2 by 2 matrix [[-5, 3], [4, 2]]?",
    },
    2159: {
        "prompt": (
            "Which of the following values of x makes the following equation true: "
            "2^x = 1/8? W) -4 X) -3 Y) 1/3 Z) 4"
        ),
    },
    2185: {
        "prompt": (
            "What values cannot be part of the domain for the following function: "
            "f(x) = x(x - 2)/((x + 3)(x - 5))?"
        ),
    },
    2239: {
        "prompt": "Which of the following is equal to the imaginary number i^3? W) -1 X) 1 Y) i Z) -i",
    },
    2227: {
        "prompt": (
            "Which of the following best describes the graph of this system of "
            "equations: y = (3/4)x + 2 and y = (4/3)x + 4? W) They are parallel "
            "X) They are perpendicular Y) They are skewed Z) They intersect at one point"
        ),
    },
    2259: {
        "prompt": "In simplest radical form, what is √4/(2√20)?",
        "answer": "√5/10",
    },
    2274: {
        "prompt": "Factor completely over the integers: x^3 - 27.",
        "answer": "(x - 3)(x^2 + 3x + 9)",
    },
    2293: {
        "answer": "x^2/100 + y^2/81 = 1",
    },
    2320: {
        "answer": "(x + 1)^2 + y^2 = 16",
    },
    2322: {
        "prompt": (
            "How many real numbers b are there such that the equation "
            "3^x + 3^-x = b has a unique real solution x? "
            "W) There are no such values of b X) There is exactly one such value of b "
            "Y) There are exactly two such values of b Z) There are infinitely many such values of b"
        ),
    },
    2386: {
        "prompt": "In the following proportion, solve for x over the real numbers: (x - 1)/8 = 6/(x + 1).",
    },
    2379: {
        "prompt": (
            "A proton exchange membrane fuel cell exchanges which of the following ions? "
            "W) OH- X) Cl- Y) H+ Z) Al"
        ),
        "answer": "Y) H+",
    },
    2425: {
        "prompt": "Express the following product in scientific notation: (4 × 10^8)(8 × 10^-3).",
        "answer": "3.2 × 10^6",
    },
    2431: {
        "prompt": "Solve the following equation for x over the real numbers: x^-2 = 81.",
        "answer": "x = ±1/9",
    },
    2486: {
        "prompt": (
            "A side of a square is represented by (x - 5). Which of the following "
            "expressions represents the area of the square? W) x^2 - 25 X) x^2 + 25 "
            "Y) x^2 - 10x + 25 Z) x^2 + 10x + 25"
        ),
        "answer": "Y) x^2 - 10x + 25",
    },
    2480: {
        "prompt": (
            "Solve for x over the real numbers: |x - 5| ≥ -7. "
            "W) x > -2 X) x ≥ -2 and x ≤ 12 Y) Null set Z) All real numbers"
        ),
    },
    2532: {
        "prompt": "What is the equation of the line tangent to the circle x^2 + y^2 = 9 at the point with coordinates (3, 0)?",
    },
    2538: {
        "prompt": "Find the value of k for which the quadratic equation x^2 - x + k = 0 has a repeated root.",
    },
    2580: {
        "prompt": "Providing your answer in scientific notation, simplify the quotient 240,000/(2 × 10^-6).",
        "answer": "1.2 × 10^11",
    },
    2592: {
        "prompt": "Determine the value of the function (f/g)(4), if f(x) = x^2 + 2x and g(x) = 3x - 5.",
    },
    2619: {
        "prompt": (
            "If x lies between 1 and 2, which of the following is the smallest? "
            "W) -1/x X) -x^2 Y) -x Z) -√x"
        ),
        "answer": "X) -x^2",
    },
    2643: {
        "prompt": "What is the coefficient of x^2 in the expansion of (2x - 3)^3?",
    },
    2663: {
        "prompt": (
            "Solve the following equation for x over the real numbers: 8^x = 16? "
            "W) 1/2 X) 3/4 Y) 4/3 Z) 2"
        ),
        "answer": "Y) 4/3",
    },
    2826: {
        "prompt": (
            "Which of the following is a rational number? W) π X) The base of a "
            "right isosceles triangle with hypotenuse 7 Y) The radius of a circle "
            "with circumference 2π Z) e^2"
        ),
    },
    2957: {
        "prompt": "If (x^2)^3 = 64, what is the value of x? W) 2 X) 4 Y) 16 Z) 64",
    },
    2962: {
        "prompt": "Evaluate the following expression for r = 7: (((4r - 7)/3)^2)/7.",
    },
    3012: {
        "prompt": (
            "In a coordinate system, a lattice point is a location with integer "
            "coordinates. How many lattice points lie on the circle x^2 + y^2 = 25? "
            "W) 4 X) 6 Y) 12 Z) 20"
        ),
    },
    3109: {
        "prompt": "What is the value of 3^0 + 2^-1 - 3?",
    },
    3136: {
        "answer": "9.013 × 10^-4",
    },
    3151: {
        "prompt": "What is the degree of the polynomial 2x^2 - x^3 + 3x - 5? W) 0 X) 1 Y) 2 Z) 3",
    },
    3221: {
        "prompt": "Which of the following numbers is equivalent to 7^-1? W) -7 X) -1/7 Y) 1/7 Z) 7",
    },
    3334: {
        "prompt": "How many points of intersection do the graphs of the functions f(x) = x^2 and g(x) = x^4 have?",
    },
    3351: {
        "prompt": (
            "Determine the domain of the function: g(x) = (2x - 2)/(4x^2 - 36x + 81)."
        ),
    },
    3431: {
        "prompt": "In terms of real numbers p and q, for what value of x is the function -x^2 + px + q maximized?",
    },
    3453: {
        "prompt": "What is the greatest common factor of the terms in the polynomial 3x^2y^2 + 12yz^2 + 6xy^3z?",
    },
    3458: {
        "answer": "x^2 - 22x + 121",
    },
    3522: {
        "prompt": "What is the leading coefficient of the polynomial x^4 - 2x^2 - 2x + 4?",
    },
    3536: {
        "prompt": "What is 2^3 - 3^2?",
    },
    3591: {
        "prompt": "If the product of two binomials is h^2 + 2h - 120 and one factor is h - 10, what is the other factor?",
    },
    3685: {
        "prompt": "What is 11^2 - 9^2?",
    },
    3731: {
        "prompt": (
            "For what real numbers is the following rational function not defined: "
            "x(x^2 - 4)/((x + 2)(x - 5))?"
        ),
    },
    3743: {
        "prompt": "What is the degree of the product of the three binomials x + 2, x^4 + x^2, and x^2 + 3?",
    },
    3793: {
        "answer": "90x^3",
    },
    3888: {
        "prompt": "Simplify the fraction with numerator x^5y^6 and denominator x^-3y^5.",
        "answer": "x^8y",
    },
    3904: {
        "prompt": (
            "For which of the following x-values is x^3 greater than or equal to x^2? "
            "W) -2 X) -1/2 Y) 1/2 Z) 2"
        ),
    },
    3924: {
        "prompt": "Simplify the following expression: a^7 times a^5",
        "answer": "a^12",
    },
    3947: {
        "answer": "x^2 - 3x - 10",
    },
    4003: {
        "prompt": "What is 5^2 - 2^5?",
    },
    4145: {
        "prompt": "Name one of the linear factors of x^2 - x - 72.",
    },
    4180: {
        "prompt": (
            "Identify all of the following three numbers that are in the domain of "
            "the function f(x) = √(36 - x^2): 1) -7; 2) -6; 3) -5."
        ),
    },
    4282: {
        "prompt": "What is the coefficient of x^2 in the expansion of (2x/3)^2?",
    },
    4301: {
        "answer": "x^2 - 16x + 64",
    },
    4352: {
        "prompt": (
            "For what real numbers is the following rational function not defined: "
            "x^2(x^2 + 1)/((x^2 - 1)(x + 8))?"
        ),
    },
    4384: {
        "prompt": "Give one of the linear factors of x^2 + 4x - 21.",
    },
    4442: {
        "prompt": "How many real solutions are there to the equation x^2 - 22x + 121 = 0?",
    },
    4467: {
        "prompt": "If the product of two binomials is h^2 + 10h - 144 and one factor is h - 8, what is the other factor?",
    },
    4567: {
        "prompt": (
            "Which of the following translations changes the graph of y = x^2 "
            "into that of y = (x + 4)^2 - 6? W) 6 units down and 4 units to the left "
            "X) 6 units down and 4 units to the right Y) 6 units up and 4 units to the left "
            "Z) 6 units up and 4 units to the right"
        ),
    },
    4581: {
        "prompt": "What is the degree of the product of the three binomials x + 3, x^5 + x^3, and x^4 - 4?",
    },
    4614: {
        "prompt": "What is 11^2 - 8^2?",
    },
    4677: {
        "prompt": "Simplify the expression x(2xy^2)^2.",
        "answer": "4x^3y^4",
    },
    4695: {
        "prompt": "Simplify the following expression: a^8 times a^3",
        "answer": "a^11",
    },
    4731: {
        "prompt": "Simplify the fraction with numerator x^4y^7 and denominator x^2y^-5.",
        "answer": "x^2y^12",
    },
    4739: {
        "prompt": "What is the leading coefficient of the polynomial -x^4 + 2x^3 - 4x + 9?",
    },
    4784: {
        "answer": "x^2 + 2x - 15",
    },
    4858: {
        "prompt": "What is the degree of the product of the three binomials x + 3, x^6 - 7x^2, and x^4 - 12?",
    },
    4871: {
        "prompt": (
            "What is the equation of the axis of symmetry for the graph of "
            "y = x^2 - 10x - 24? W) x = -12 X) x = -5 Y) x = 5 Z) x = 12"
        ),
    },
    4900: {
        "prompt": "When x^2 - 2x + 3 is divided by x - 2, what is the remainder?",
    },
    4951: {
        "prompt": "If the product of two binomials is a^2 - 3a - 180 and one factor is a + 12, what is the other factor?",
    },
    4972: {
        "prompt": "What is 13^2 - 9^2?",
    },
    5000: {
        "prompt": "Find the value of the following expression: (11^3 - 22) / 11.",
    },
    5004: {
        "answer": "10^-16",
    },
}

REVIEW_ONLY_INDICES = {
    985,
    995,
}

TEXT_REPLACEMENTS = {
    "𝑥": "x",
    "𝑦": "y",
    "𝑓": "f",
    "𝑔": "g",
    "º": "°",
    "microgams": "micrograms",
    "coefficent": "coefficient",
    "parentheis": "parenthesis",
    "DNAengineering": "DNA engineering",
    " & ": " and ",
}


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


def normalize_minus(value: str) -> str:
    return value.replace("−", "-").replace("–", "-")


def normalize_scientific_notation(value: str) -> str:
    def replace_times_10(match: re.Match[str]) -> str:
        coefficient = match.group(1)
        exponent = normalize_minus(match.group(2))
        return f"{coefficient} × 10^{exponent}"

    value = re.sub(
        r"\b(\d+(?:\.\d+)?)\s*(?:×|x|\*)\s*10\s*\^?\s*([−–-]?\d+)\b",
        replace_times_10,
        value,
    )
    value = re.sub(r"\b10[−–-](\d+)\b", r"10^-\1", value)
    return value


def normalize_math_markup(value: str, is_math: bool) -> str:
    original = value
    value = value.strip()

    for before, after in TEXT_REPLACEMENTS.items():
        value = value.replace(before, after)

    value = normalize_scientific_notation(value)

    if is_math:
        value = normalize_minus(value)
        value = re.sub(r"!([^!]+)!", r"|\1|", value)
        value = re.sub(r"(?<![A-Za-z])([a-z])([2-9])\b", r"\1^\2", value)
        value = re.sub(r"(?<![A-Za-z])([a-z])([1-9]\.\d+)\b", r"\1^\2", value)

    value = re.sub(r"\s+", " ", value).strip()
    return value if value else original.strip()


def apply_manual_fix(
    index: int,
    prompt: str,
    answer: str,
) -> tuple[str, str, list[str]]:
    fix = MANUAL_FIXES.get(index)
    if not fix:
        return prompt, answer, []

    notes = []
    if "prompt" in fix and fix["prompt"] != prompt:
        prompt = fix["prompt"]
        notes.append("manual prompt repair")
    if "answer" in fix and fix["answer"] != answer:
        answer = fix["answer"]
        notes.append("manual answer repair")
    return prompt, answer, notes


def needs_review(index: int, question: dict[str, object]) -> bool:
    if index in REVIEW_ONLY_INDICES:
        return True

    text = " | ".join(
        [
            str(question["question"]),
            str(question["answer"]),
            " | ".join(choice["text"] for choice in question["choices"]),
        ]
    )

    if not str(question["answer"]).strip():
        return True
    if "�" in text:
        return True
    if question["category"] == "Math":
        suspicious_patterns = (
            r"\b[abchrtxyz]\s+[2-9](?=\s*(?:[+*/^=;,\)]|$))",
            r"\b\d+\s+\d+\s*;",
            r"\(\s*\d+\s+\d+\s*\)",
        )
        return any(re.search(pattern, text) for pattern in suspicious_patterns)

    return False


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
    is_math = category == "Math"
    original_prompt = prompt
    original_answer = answer
    prompt, answer, notes = apply_manual_fix(index, prompt, answer)
    prompt = normalize_math_markup(prompt, is_math=is_math)
    answer = normalize_math_markup(answer, is_math=is_math)
    if prompt != original_prompt or answer != original_answer:
        notes.append("normalized math/text formatting")

    prompt, choices = split_choices(prompt) if question_type == "Multiple Choice" else (prompt, [])
    choices = [
        {
            "label": choice["label"],
            "text": normalize_math_markup(choice["text"], is_math=is_math),
        }
        for choice in choices
    ]

    question = {
        "id": f"q-{index + 1:04d}",
        "rawIndex": index,
        "setId": set_id,
        "questionNumber": question_number,
        "category": category,
        "type": TYPE_LABELS[question_type],
        "question": prompt,
        "answer": answer,
        "answerLabel": answer_label(answer),
        "choices": choices,
        "cleanupNotes": sorted(set(notes)),
    }
    question["needsReview"] = needs_review(index, question)
    return question


def write_report(questions: list[dict[str, object]]) -> None:
    changed = [question for question in questions if question["cleanupNotes"]]
    review = [question for question in questions if question["needsReview"]]

    lines = [
        "# Question Cleanup Report",
        "",
        f"- Total questions: {len(questions)}",
        f"- Questions changed by cleanup: {len(changed)}",
        f"- Questions still marked for review: {len(review)}",
        "",
        "## Still Needs Review",
        "",
    ]

    if review:
        for question in review:
            lines.extend(
                [
                    f"### {question['id']} ({question['category']} set {question['setId']} #{question['questionNumber']})",
                    "",
                    f"- Notes: {', '.join(question['cleanupNotes']) or 'unresolved suspicious formatting'}",
                    f"- Question: {question['question']}",
                    f"- Answer: {question['answer']}",
                    "",
                ]
            )
    else:
        lines.append("No unresolved rows detected.")
        lines.append("")

    lines.extend(["## Changed Questions", ""])
    for question in changed:
        lines.extend(
            [
                f"- {question['id']} ({question['category']} set {question['setId']} #{question['questionNumber']}): "
                f"{', '.join(question['cleanupNotes'])}",
            ]
        )

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    rows = load_rows()
    questions = [convert_row(index, row) for index, row in enumerate(rows)]

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(questions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    write_report(questions)

    categories = Counter(question["category"] for question in questions)
    types = Counter(question["type"] for question in questions)
    changed_count = sum(1 for question in questions if question["cleanupNotes"])
    review_count = sum(1 for question in questions if question["needsReview"])
    print(f"Wrote {len(questions)} questions to {OUTPUT_PATH.relative_to(ROOT)}")
    print(f"Wrote cleanup report to {REPORT_PATH.relative_to(ROOT)}")
    print(f"Changed questions: {changed_count}")
    print(f"Questions needing review: {review_count}")
    print("Categories:")
    for category, count in sorted(categories.items()):
        print(f"  {category}: {count}")
    print("Types:")
    for question_type, count in sorted(types.items()):
        print(f"  {question_type}: {count}")


if __name__ == "__main__":
    main()
