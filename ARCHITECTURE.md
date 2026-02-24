# ARCHITECTURE.md – Serverless RAG on AWS

## 1. High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SERVERLESS RAG SYSTEM                              │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌──────────────┐
                              │     USER     │
                              └──────┬───────┘
                                     │
                 ┌───────────────────┼───────────────────┐
                 │                   │                   │
          [QUERY PATH]        [INGEST PATH]             │
                 │                   │                   │
                 ▼                   ▼                   │
         ┌──────────────┐    ┌──────────────┐           │
         │ API Gateway  │    │  S3 Bucket   │           │
         │  POST /chat  │    │  (uploads/)  │           │
         └──────┬───────┘    └──────┬───────┘           │
                │                   │                   │
                │ invoke            │ S3 Event          │
                ▼                   ▼                   │
         ┌──────────────┐    ┌──────────────┐          │
         │ Chat Lambda  │    │Ingest Lambda │          │
         │ (Python 3.11)│    │(Python 3.11) │          │
         └──────┬───────┘    └──────┬───────┘          │
                │                   │                   │
                │ ┌─────────────────┘                   │
                │ │                                     │
                ▼ ▼                                     │
         ┌─────────────────────────────┐               │
         │     AMAZON BEDROCK          │               │
         │  ┌────────────────────────┐ │               │
         │  │ Titan Embeddings       │ │               │
         │  │ (amazon.titan-embed)   │ │               │
         │  └────────────────────────┘ │               │
         │  ┌────────────────────────┐ │               │
         │  │ Claude v2              │ │               │
         │  │ (anthropic.claude-v2)  │ │               │
         │  └────────────────────────┘ │               │
         └──────────────┬──────────────┘               │
                        │                               │
                        │ read/write                    │
                        ▼                               │
         ┌─────────────────────────────┐               │
         │    DATA STORAGE LAYER       │               │
         │  ┌────────────────────────┐ │               │
         │  │ S3 Vector Store        │ │               │
         │  │ tenant_id/vectors/     │ │               │
         │  └────────────────────────┘ │               │
         │  ┌────────────────────────┐ │               │
         │  │ DynamoDB               │ │               │
         │  │ (Cost Tracking)        │ │               │
         │  └────────────────────────┘ │               │
         └──────────────┬──────────────┘               │
                        │                               │
                        │ logs/metrics                  │
                        ▼                               │
         ┌─────────────────────────────┐               │
         │   MONITORING & SECURITY     │               │
         │  ┌────────────────────────┐ │               │
         │  │ CloudWatch Logs/Alarms │ │               │
         │  └────────────┬───────────┘ │               │
         │  ┌────────────▼───────────┐ │               │
         │  │ SNS (Email Alerts)     │◄┼───────────────┘
         │  └────────────────────────┘ │
         │  ┌────────────────────────┐ │
         │  │ Guardrails             │ │
         │  │ (PII + Injection)      │ │
         │  └────────────────────────┘ │
         └─────────────────────────────┘
```

User → API Gateway → Chat Lambda  
Document Upload → S3 → Ingest Lambda  
Embeddings + LLM → Bedrock  
Vectors → S3 (vector store format)  
Cost + Metrics → DynamoDB + CloudWatch  

