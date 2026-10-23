"""Enrich hj-ox-7a-2024.json phonetics from dictionaryapi.dev. No invented IPA."""
import json, time, urllib.request, urllib.error, re, sys
from pathlib import Path

SRC = Path(r"C:\Users\user\Documents\vocab_helper\assets\wordbooks\hj-ox-7a-2024.json")
OUT = SRC
CACHE = Path(r"C:\Users\user\Documents\vocab_helper\scripts\_phonetic_cache.json")

UK_HINTS = set("ɒɑːəɜːɪəʊɔːʌ")  # rough British markers in IPA strings

def normalize_ipa(s: str) -> str:
    s = (s or "").strip()
    if not s:
        return ""
    s = s.replace("[", "/").replace("]", "/")
    if not s.startswith("/"):
        s = "/" + s
    if not s.endswith("/"):
        s = s + "/"
    # collapse double slashes
    s = re.sub(r"/{2,}", "/", s)
    return s

def score_phonetic(ph: str) -> int:
    """Higher = more British-like."""
    if not ph:
        return -1
    score = 0
    if any(h in ph for h in ("ɒ", "ɑː", "ə", "ɜː", "ɪə", "əʊ", "ɔː")):
        score += 5
    if "ɝ" in ph or "ɚ" in ph or "æ" in ph and "ɑ" not in ph:
        score -= 1  # slight US penalty, still usable
    if ph.startswith("/") and ph.endswith("/"):
        score += 1
    return score

def fetch_entry(word: str):
    url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{urllib.request.quote(word)}"
    req = urllib.request.Request(url, headers={"User-Agent": "vocab_helper-r44/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise
    except Exception:
        return None

def pick_from_entry(data):
    if not data or not isinstance(data, list):
        return "", ""
    phonetics = []
    examples = []
    for entry in data:
        for p in entry.get("phonetics") or []:
            text = (p.get("text") or "").strip()
            if text:
                phonetics.append(text)
        # also top-level phonetic
        top = (entry.get("phonetic") or "").strip()
        if top:
            phonetics.append(top)
        for m in entry.get("meanings") or []:
            for d in m.get("definitions") or []:
                ex = (d.get("example") or "").strip()
                if ex and len(ex.split()) <= 16:
                    examples.append(ex)
    best = ""
    best_score = -1
    for ph in phonetics:
        sc = score_phonetic(ph)
        if sc > best_score:
            best_score = sc
            best = ph
    return normalize_ipa(best), (examples[0] if examples else "")

def main():
    data = json.loads(SRC.read_text(encoding="utf-8"))
    words = data["words"]
    cache = {}
    if CACHE.exists():
        cache = json.loads(CACHE.read_text(encoding="utf-8"))

    single = [w for w in words if " " not in (w.get("word") or "")]
    print(f"total={len(words)} single={len(single)} phrases={len(words)-len(single)}")

    filled = 0
    ex_filled = 0
    fail = 0
    for i, w in enumerate(words):
        word = (w.get("word") or "").strip()
        is_phrase = " " in word
        if is_phrase:
            # leave empty unless already set
            continue
        key = word.lower()
        if key in cache:
            ph, ex = cache[key].get("phonetic", ""), cache[key].get("example", "")
        else:
            # rate limit
            time.sleep(0.35)
            try:
                entry = fetch_entry(word)
                ph, ex = pick_from_entry(entry)
            except Exception as e:
                print(f"ERR {word}: {e}")
                ph, ex = "", ""
                fail += 1
            cache[key] = {"phonetic": ph, "example": ex}
            if (i + 1) % 25 == 0:
                CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
                print(f"progress {i+1}/{len(words)} filled_so_far...")

        if ph:
            w["phonetic"] = ph
            filled += 1
        # example optional
        if ex and not (w.get("example") or "").strip():
            w["example"] = ex
            ex_filled += 1

    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")

    # update source note
    src = data.get("source") or ""
    note = "phonetic: dictionaryapi.dev + spot-check (R44)"
    if note not in src:
        data["source"] = (src + "；" + note).strip("；")

    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    singles = [w for w in words if " " not in (w.get("word") or "")]
    with_ph = sum(1 for w in singles if (w.get("phonetic") or "").strip())
    with_ex = sum(1 for w in singles if (w.get("example") or "").strip())
    ratio = with_ph / len(singles) if singles else 0
    print(f"single phonetic {with_ph}/{len(singles)} = {ratio:.1%}")
    print(f"single example {with_ex}/{len(singles)} = {with_ex/len(singles):.1%}")
    print(f"fail_requests~{fail}")
    # spot checks
    for target in ("guitar", "honest", "patient", "improve", "confident"):
        hit = next((w for w in words if w.get("word") == target), None)
        print(f"  {target}: {hit.get('phonetic') if hit else 'MISSING'}")

if __name__ == "__main__":
    main()
