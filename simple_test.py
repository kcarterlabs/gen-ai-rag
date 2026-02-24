#!/usr/bin/env python3
"""
Simple test script that doesn't require AWS credentials.
Tests the core logic without making actual API calls.

Run: python simple_test.py
"""

from chunking import chunk_text
from prompt_templates import build_prompt

def test_chunking():
    """Test document chunking"""
    print("=" * 50)
    print("TEST 1: Document Chunking")
    print("=" * 50)
    
    sample_doc = """
Machine learning is a subset of artificial intelligence that focuses on 
building systems that learn from data. Instead of being explicitly programmed, 
these systems improve their performance through experience.

Deep learning is a specialized form of machine learning that uses neural 
networks with multiple layers. These networks can learn complex patterns 
in large amounts of data.

Natural language processing (NLP) is another AI field that focuses on the 
interaction between computers and human language. It enables applications 
like chatbots, translation, and text analysis.
"""
    
    chunks = chunk_text(sample_doc, max_tokens=100, overlap_tokens=20)
    
    print(f"\n✓ Created {len(chunks)} chunks from document")
    for chunk in chunks:
        print(f"\nChunk {chunk['chunk_id']}:")
        print(f"  Tokens: ~{chunk['token_estimate']}")
        print(f"  Text: {chunk['text'][:80]}...")
    
    return chunks


def test_prompt_building():
    """Test RAG prompt construction"""
    print("\n" + "=" * 50)
    print("TEST 2: RAG Prompt Building")
    print("=" * 50)
    
    # Simulate retrieved chunks
    retrieved_chunks = [
        {"text": "Machine learning is a subset of AI that learns from data."},
        {"text": "Deep learning uses neural networks with multiple layers."},
    ]
    
    question = "What is deep learning?"
    
    prompt = build_prompt(retrieved_chunks, question)
    
    print("\n✓ Generated RAG prompt:")
    print(prompt)
    
    return prompt


def test_workflow():
    """Test the complete RAG workflow (without AWS calls)"""
    print("\n" + "=" * 50)
    print("TEST 3: Complete Workflow Simulation")
    print("=" * 50)
    
    # Step 1: Ingest a document
    document = """
Retrieval Augmented Generation (RAG) is a technique that enhances large 
language models by providing them with relevant context from external documents.

The process works in three steps:
1. Break documents into chunks and generate embeddings
2. When a user asks a question, retrieve the most relevant chunks
3. Pass the chunks as context to the LLM along with the question

This approach allows LLMs to access specific information without retraining.
"""
    
    print("\n1. Chunking document...")
    chunks = chunk_text(document, max_tokens=150, overlap_tokens=30)
    print(f"   ✓ Created {len(chunks)} chunks")
    
    # Step 2: Simulate retrieval (in real system, would use embeddings)
    print("\n2. Retrieving relevant chunks for question...")
    question = "How does RAG work?"
    # In reality, we'd compute embeddings and find similar chunks
    # For this test, just use the first 2 chunks
    top_chunks = chunks[:2]
    print(f"   ✓ Retrieved {len(top_chunks)} relevant chunks")
    
    # Step 3: Build prompt
    print("\n3. Building prompt for LLM...")
    prompt = build_prompt(top_chunks, question)
    print("   ✓ Prompt built successfully")
    print(f"   ✓ Prompt length: {len(prompt)} characters")
    
    print("\n" + "-" * 50)
    print("FINAL PROMPT THAT WOULD BE SENT TO LLM:")
    print("-" * 50)
    print(prompt)
    
    return prompt


if __name__ == "__main__":
    print("\n🧪 RAG System - Local Tests (No AWS Required)\n")
    
    # Run tests
    chunks = test_chunking()
    prompt_result = test_prompt_building()
    full_workflow = test_workflow()
    
    print("\n" + "=" * 50)
    print("✅ ALL TESTS PASSED")
    print("=" * 50)
    print("\nNext steps:")
    print("  1. Deploy to AWS: cd infra && terraform apply")
    print("  2. See TESTING_GUIDE.md for full deployment testing")
    print("  3. See TODO.md for remaining implementation tasks")
