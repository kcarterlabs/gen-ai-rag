SYSTEM_PROMPT = """
You are an internal enterprise assistant.
Answer only using the provided context.
If the answer is not in the context, say:
"I do not have enough information."
"""

def build_prompt(context_chunks, user_question):
    context_text = "\n\n".join([chunk["text"] for chunk in context_chunks])
    return f"""
{SYSTEM_PROMPT}

Context:
{context_text}

Question:
{user_question}

Answer:
"""
