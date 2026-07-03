# Raw Question Files

Put the large Python question file in this folder, for example:

```text
data/raw/questions.py
```

This folder is for the original source file only. The Flutter app should load a converted JSON file from `assets/questions/`.

Run the converter whenever `questions.py` changes:

```sh
python3 tools/convert_questions.py
```

The converter reads the six-element rows and writes:

```text
assets/questions/questions.json
```
