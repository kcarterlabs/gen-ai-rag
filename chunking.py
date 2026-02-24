import re
from typing import List, Dict


def approximate_token_count(text: str) -> int:
    """
    Rough token estimate.
    Most LLMs average ~4 characters per token in English.
    """
    return max(1, len(text) // 4)


def split_into_paragraphs(text: str) -> List[str]:
    """
    Splits text into paragraphs using double newlines.
    Cleans excessive whitespace.
    """
    paragraphs = re.split(r"\n\s*\n", text)
    return [p.strip() for p in paragraphs if p.strip()]


def chunk_text(
    text: str,
    max_tokens: int = 500,
    overlap_tokens: int = 50
) -> List[Dict]:
    """
    Chunk text into overlapping segments based on approximate token size.

    Returns list of:
    {
        "chunk_id": int,
        "text": str,
        "token_estimate": int
    }
    """

    paragraphs = split_into_paragraphs(text)

    chunks = []
    current_chunk = ""
    current_tokens = 0
    chunk_id = 0

    for paragraph in paragraphs:
        paragraph_tokens = approximate_token_count(paragraph)

        # If paragraph alone exceeds max, hard split
        if paragraph_tokens > max_tokens:
            words = paragraph.split()
            temp_chunk = []
            for word in words:
                temp_chunk.append(word)
                if approximate_token_count(" ".join(temp_chunk)) >= max_tokens:
                    chunk_text_block = " ".join(temp_chunk)
                    chunks.append({
                        "chunk_id": chunk_id,
                        "text": chunk_text_block,
                        "token_estimate": approximate_token_count(chunk_text_block)
                    })
                    chunk_id += 1
                    temp_chunk = []
            continue

        # If adding paragraph exceeds max_tokens, finalize current chunk
        if current_tokens + paragraph_tokens > max_tokens:
            chunks.append({
                "chunk_id": chunk_id,
                "text": current_chunk.strip(),
                "token_estimate": current_tokens
            })
            chunk_id += 1

            # Start new chunk with overlap
            overlap_text = current_chunk.split()[-overlap_tokens:]
            current_chunk = " ".join(overlap_text) + "\n\n" + paragraph
            current_tokens = approximate_token_count(current_chunk)
        else:
            current_chunk += "\n\n" + paragraph
            current_tokens = approximate_token_count(current_chunk)

    # Add final chunk
    if current_chunk.strip():
        chunks.append({
            "chunk_id": chunk_id,
            "text": current_chunk.strip(),
            "token_estimate": current_tokens
        })

    return chunks
