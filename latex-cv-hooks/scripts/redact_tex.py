#!/usr/bin/env python3
import io
import sys

def main() -> int:
    if len(sys.argv) != 3:
        print("usage: redact_tex.py <src> <dest>")
        return 2

    src_path, dest_path = sys.argv[1], sys.argv[2]
    if "german" in src_path.lower():
        class_name = "resume_redacted_de"
    else:
        class_name = "resume_redacted_en"

    class_token = "{resume}"
    class_replacement = "{" + class_name + "}"

    with io.open(src_path, "r", encoding="utf-8") as src_file:
        lines = src_file.readlines()

    with io.open(dest_path, "w", encoding="utf-8") as dest_file:
        for line in lines:
            if class_token in line:
                dest_file.write(line.replace(class_token, class_replacement))
            else:
                dest_file.write(line)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
