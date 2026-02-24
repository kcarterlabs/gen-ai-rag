#!/usr/bin/env python3
"""
Compare POC vs Moderate Usage costs
"""

from cost_simulator import CostSimulator, ModelPricing, InfraPricing, Usage

simulator = CostSimulator(ModelPricing(), InfraPricing())

print("=" * 70)
print("COST COMPARISON: POC vs MODERATE USAGE")
print("=" * 70)

# POC Scenario
print("\n1️⃣  POC SCENARIO (minimal testing)")
print("-" * 70)
poc_usage = Usage(
    queries_per_month=50,           # ← Just testing
    documents_per_month=10,         # ← Small dataset
    avg_doc_tokens=5000,
    avg_query_tokens=50,
    avg_context_tokens=1500,
    avg_output_tokens=300
)

poc_results = simulator.monthly_cost(poc_usage)
print(f"Queries per month:     50")
print(f"Documents ingested:    10")
print()
for k, v in poc_results.items():
    print(f"  {k:20s}: ${v:.2f}")

# Moderate Usage (what's in cost_simulator.py)
print("\n\n2️⃣  MODERATE USAGE SCENARIO (real application)")
print("-" * 70)
moderate_usage = Usage(
    queries_per_month=10000,        # ← 10,000 queries! ⚠️
    documents_per_month=1000,       # ← 1,000 documents!
    avg_doc_tokens=10000,
    avg_query_tokens=50,
    avg_context_tokens=1500,
    avg_output_tokens=500
)

moderate_results = simulator.monthly_cost(moderate_usage)
print(f"Queries per month:     10,000  ← This is why!")
print(f"Documents ingested:    1,000")
print()
for k, v in moderate_results.items():
    print(f"  {k:20s}: ${v:.2f}")

print("\n" + "=" * 70)
print("THE $41 IS FROM THE MODERATE USAGE EXAMPLE")
print("=" * 70)
print(f"\nPOC cost:      ${poc_results['total_monthly']:.2f}/month")
print(f"Moderate cost: ${moderate_results['total_monthly']:.2f}/month")
print()
print("📊 The difference:")
print(f"  • POC uses 50 queries/month")
print(f"  • Moderate uses 10,000 queries/month (200x more!)")
print(f"  • Generation cost scales with query volume")
print()
