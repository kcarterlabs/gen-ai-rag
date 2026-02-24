from dataclasses import dataclass


# ==============================
# Pricing Models
# ==============================

@dataclass
class ModelPricing:
    embedding_per_1k: float = 0.0001
    input_per_1k: float = 0.002
    output_per_1k: float = 0.002


@dataclass
class InfraPricing:
    lambda_per_million_requests: float = 0.20
    lambda_per_gb_second: float = 0.00001667
    s3_per_gb_month: float = 0.023
    dynamodb_per_million_writes: float = 1.25
    api_gateway_per_million_requests: float = 1.00


# ==============================
# Usage Model
# ==============================

@dataclass
class Usage:
    queries_per_month: int
    documents_per_month: int
    avg_doc_tokens: int
    avg_query_tokens: int
    avg_context_tokens: int
    avg_output_tokens: int
    lambda_memory_mb: int = 512
    lambda_duration_ms: int = 1000
    avg_doc_size_kb: int = 200


# ==============================
# Cost Simulator
# ==============================

class CostSimulator:
    def __init__(self, model_pricing: ModelPricing, infra_pricing: InfraPricing):
        self.model = model_pricing
        self.infra = infra_pricing

    def embedding_cost(self, tokens):
        return (tokens / 1000) * self.model.embedding_per_1k

    def query_cost(self, query_tokens, context_tokens, output_tokens):
        input_tokens = query_tokens + context_tokens
        input_cost = (input_tokens / 1000) * self.model.input_per_1k
        output_cost = (output_tokens / 1000) * self.model.output_per_1k
        return input_cost + output_cost

    def lambda_cost(self, total_invocations, memory_mb, duration_ms):
        request_cost = (total_invocations / 1_000_000) * self.infra.lambda_per_million_requests

        gb_seconds = (
            (memory_mb / 1024)
            * (duration_ms / 1000)
            * total_invocations
        )

        compute_cost = gb_seconds * self.infra.lambda_per_gb_second

        return request_cost + compute_cost

    def s3_cost(self, total_gb):
        return total_gb * self.infra.s3_per_gb_month

    def dynamodb_cost(self, total_writes):
        return (total_writes / 1_000_000) * self.infra.dynamodb_per_million_writes

    def api_gateway_cost(self, total_requests):
        return (total_requests / 1_000_000) * self.infra.api_gateway_per_million_requests

    def monthly_cost(self, usage: Usage):
        # Model Costs
        embed_per_doc = self.embedding_cost(usage.avg_doc_tokens)
        total_embed = embed_per_doc * usage.documents_per_month

        per_query = self.query_cost(
            usage.avg_query_tokens,
            usage.avg_context_tokens,
            usage.avg_output_tokens
        )
        total_query = per_query * usage.queries_per_month

        # Infra Costs
        total_invocations = usage.queries_per_month + usage.documents_per_month
        lambda_cost = self.lambda_cost(
            total_invocations,
            usage.lambda_memory_mb,
            usage.lambda_duration_ms
        )

        total_storage_gb = (
            usage.documents_per_month * usage.avg_doc_size_kb
        ) / (1024 * 1024)

        s3_cost = self.s3_cost(total_storage_gb)

        dynamodb_cost = self.dynamodb_cost(total_invocations)
        api_cost = self.api_gateway_cost(usage.queries_per_month)

        total = (
            total_embed
            + total_query
            + lambda_cost
            + s3_cost
            + dynamodb_cost
            + api_cost
        )

        return {
            "embedding": round(total_embed, 2),
            "generation": round(total_query, 2),
            "lambda": round(lambda_cost, 2),
            "s3": round(s3_cost, 2),
            "dynamodb": round(dynamodb_cost, 2),
            "api_gateway": round(api_cost, 2),
            "total_monthly": round(total, 2),
        }


if __name__ == "__main__":
    simulator = CostSimulator(ModelPricing(), InfraPricing())

    usage = Usage(
        queries_per_month=10000,
        documents_per_month=1000,
        avg_doc_tokens=10000,
        avg_query_tokens=50,
        avg_context_tokens=1500,
        avg_output_tokens=500
    )

    results = simulator.monthly_cost(usage)

    print("===== Full RAG Cost Simulation =====")
    for k, v in results.items():
        print(f"{k}: ${v}")
