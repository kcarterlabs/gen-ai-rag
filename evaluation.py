"""
Evaluation metrics for RAG system
- Precision@k
- Recall@k
- Mean Reciprocal Rank (MRR)
- NDCG (Normalized Discounted Cumulative Gain)
- Answer relevance scoring
"""

import json
from typing import List, Dict, Set
from dataclasses import dataclass
import numpy as np


@dataclass
class RetrievalResult:
    """Single retrieval result"""
    chunk_id: str
    score: float
    rank: int
    is_relevant: bool = False


@dataclass
class EvaluationMetrics:
    """Container for evaluation metrics"""
    precision_at_k: float
    recall_at_k: float
    mrr: float
    ndcg: float
    num_queries: int
    
    def to_dict(self) -> Dict:
        return {
            "precision@k": round(self.precision_at_k, 4),
            "recall@k": round(self.recall_at_k, 4),
            "mrr": round(self.mrr, 4),
            "ndcg": round(self.ndcg, 4),
            "num_queries": self.num_queries
        }


def precision_at_k(retrieved: List[str], relevant: Set[str], k: int) -> float:
    """
    Calculate Precision@k
    
    Args:
        retrieved: List of retrieved document IDs (ordered by rank)
        relevant: Set of relevant document IDs
        k: Number of top results to consider
        
    Returns:
        Precision@k score (0-1)
    """
    if k <= 0 or not retrieved:
        return 0.0
    
    top_k = retrieved[:k]
    relevant_retrieved = sum(1 for doc in top_k if doc in relevant)
    
    return relevant_retrieved / k


def recall_at_k(retrieved: List[str], relevant: Set[str], k: int) -> float:
    """
    Calculate Recall@k
    
    Args:
        retrieved: List of retrieved document IDs (ordered by rank)
        relevant: Set of relevant document IDs
        k: Number of top results to consider
        
    Returns:
        Recall@k score (0-1)
    """
    if not relevant or k <= 0:
        return 0.0
    
    top_k = retrieved[:k]
    relevant_retrieved = sum(1 for doc in top_k if doc in relevant)
    
    return relevant_retrieved / len(relevant)


def mean_reciprocal_rank(retrieved: List[str], relevant: Set[str]) -> float:
    """
    Calculate Mean Reciprocal Rank (MRR)
    
    Args:
        retrieved: List of retrieved document IDs (ordered by rank)
        relevant: Set of relevant document IDs
        
    Returns:
        MRR score (0-1)
    """
    for i, doc in enumerate(retrieved, 1):
        if doc in relevant:
            return 1.0 / i
    
    return 0.0


def dcg_at_k(relevances: List[float], k: int) -> float:
    """
    Calculate Discounted Cumulative Gain at k
    
    Args:
        relevances: List of relevance scores (ordered by rank)
        k: Number of top results to consider
        
    Returns:
        DCG@k score
    """
    relevances = relevances[:k]
    if not relevances:
        return 0.0
    
    return sum(
        (2 ** rel - 1) / np.log2(i + 2)
        for i, rel in enumerate(relevances)
    )


def ndcg_at_k(retrieved_relevances: List[float], ideal_relevances: List[float], k: int) -> float:
    """
    Calculate Normalized Discounted Cumulative Gain at k
    
    Args:
        retrieved_relevances: Relevance scores in retrieved order
        ideal_relevances: Relevance scores in ideal order (sorted desc)
        k: Number of top results to consider
        
    Returns:
        NDCG@k score (0-1)
    """
    dcg = dcg_at_k(retrieved_relevances, k)
    idcg = dcg_at_k(sorted(ideal_relevances, reverse=True), k)
    
    if idcg == 0:
        return 0.0
    
    return dcg / idcg


def evaluate_retrieval(
    queries_and_relevance: List[Dict],
    k: int = 5
) -> EvaluationMetrics:
    """
    Evaluate retrieval performance across multiple queries
    
    Args:
        queries_and_relevance: List of dicts with:
            - "retrieved": List of retrieved doc IDs
            - "relevant": Set/List of relevant doc IDs
            - "scores": Optional relevance scores (0-3)
        k: Number of top results to consider
        
    Returns:
        EvaluationMetrics with aggregated scores
    """
    precision_scores = []
    recall_scores = []
    mrr_scores = []
    ndcg_scores = []
    
    for item in queries_and_relevance:
        retrieved = item["retrieved"]
        relevant = set(item["relevant"])
        
        # Precision and Recall
        precision_scores.append(precision_at_k(retrieved, relevant, k))
        recall_scores.append(recall_at_k(retrieved, relevant, k))
        
        # MRR
        mrr_scores.append(mean_reciprocal_rank(retrieved, relevant))
        
        # NDCG (if relevance scores provided)
        if "scores" in item:
            retrieved_scores = item["scores"][:k]
            ideal_scores = sorted(item["scores"], reverse=True)
            ndcg_scores.append(ndcg_at_k(retrieved_scores, ideal_scores, k))
    
    return EvaluationMetrics(
        precision_at_k=np.mean(precision_scores) if precision_scores else 0.0,
        recall_at_k=np.mean(recall_scores) if recall_scores else 0.0,
        mrr=np.mean(mrr_scores) if mrr_scores else 0.0,
        ndcg=np.mean(ndcg_scores) if ndcg_scores else 0.0,
        num_queries=len(queries_and_relevance)
    )


def calculate_answer_relevance(
    question: str,
    answer: str,
    context_chunks: List[str]
) -> Dict[str, float]:
    """
    Calculate answer quality metrics (basic heuristics)
    
    Args:
        question: User's question
        answer: Generated answer
        context_chunks: Context provided to LLM
        
    Returns:
        Dictionary of relevance metrics
    """
    metrics = {}
    
    # Answer length
    metrics["answer_length"] = len(answer)
    
    # Context utilization (rough estimate)
    context_text = " ".join(context_chunks).lower()
    answer_lower = answer.lower()
    
    # Count how many context words appear in answer
    context_words = set(context_text.split())
    answer_words = set(answer_lower.split())
    overlap = len(context_words & answer_words)
    
    metrics["context_overlap_ratio"] = (
        overlap / len(context_words) if context_words else 0.0
    )
    
    # Check if answer contains "I do not have" or similar uncertainty
    uncertainty_phrases = [
        "i do not have",
        "i don't have",
        "not sure",
        "cannot determine",
        "insufficient information"
    ]
    
    metrics["has_uncertainty"] = any(
        phrase in answer_lower for phrase in uncertainty_phrases
    )
    
    # Question term coverage
    question_terms = set(question.lower().split())
    question_coverage = len(question_terms & answer_words) / len(question_terms) if question_terms else 0.0
    metrics["question_coverage"] = question_coverage
    
    return metrics


class EvaluationDataset:
    """Manage evaluation dataset for RAG system"""
    
    def __init__(self, dataset_path: str = None):
        self.dataset_path = dataset_path
        self.queries = []
    
    def load_dataset(self) -> List[Dict]:
        """Load evaluation dataset from JSON file"""
        if not self.dataset_path:
            return []
        
        with open(self.dataset_path, 'r') as f:
            self.queries = json.load(f)
        
        return self.queries
    
    def add_query(
        self, 
        query: str, 
        relevant_chunks: List[str],
        expected_answer: str = None
    ):
        """Add a query to the evaluation dataset"""
        self.queries.append({
            "query": query,
            "relevant_chunks": relevant_chunks,
            "expected_answer": expected_answer
        })
    
    def save_dataset(self, path: str = None):
        """Save evaluation dataset to JSON file"""
        save_path = path or self.dataset_path
        if not save_path:
            raise ValueError("No dataset path specified")
        
        with open(save_path, 'w') as f:
            json.dumps(self.queries, f, indent=2)
    
    def get_sample_dataset(self) -> List[Dict]:
        """Return a sample evaluation dataset for testing"""
        return [
            {
                "query": "What is machine learning?",
                "relevant_chunks": ["chunk_ml_def", "chunk_ml_overview"],
                "expected_answer": "Machine learning is a subset of AI..."
            },
            {
                "query": "How does deep learning work?",
                "relevant_chunks": ["chunk_dl_def", "chunk_neural_nets"],
                "expected_answer": "Deep learning uses neural networks..."
            }
        ]
