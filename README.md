# LLM Testing & Agentic Engineering Masterclass

> A Zero-to-Hero roadmap for the **Senior SDET → AI/Agentic Automation Engineer** transition — covering LLM evaluation frameworks, RAG pipeline testing, agentic system validation, and GenAI observability. Runs entirely free on local hardware via Ollama.

---

## 🎯 Who this is for

| Profile | Fit |
|---------|-----|
| Senior SDET curious about AI/ML quality engineering | ✅ Primary audience |
| QA Engineer asked to "add AI testing" without knowing where to start | ✅ Starts from first principles |
| Staff Engineer building or reviewing an LLM test strategy | ✅ Every part ends with a senior architectural challenge |
| Developer shipping a RAG product who wants to understand evaluation | ✅ Hands-on Python examples throughout |

---

## 📐 Intention

LLM outputs are probabilistic — the same prompt can produce different answers on consecutive runs. Traditional deterministic assertions (`assertEqual`) break down immediately. This guide teaches you a fundamentally different evaluation mindset: **metric-based, threshold-driven, trace-observable** quality engineering for AI systems.

The goal is to produce engineers who can:
- Choose and implement the right evaluation framework (DeepEval, Ragas, or Promptfoo) for a given problem
- Write evaluation suites that are repeatable and CI-friendly despite non-deterministic outputs
- Detect hallucination, faithfulness drift, and prompt injection in production pipelines
- Instrument LLM calls with OpenTelemetry GenAI spans and correlate test failures to traces
- Reason about where AI belongs in a test automation stack — and where it does not (per ADR-019)

Everything runs **locally and for free**. No OpenAI key, no cloud spend, no trial account required.

---

## 📖 Curriculum

The full guide lives in **[LLM_TESTING_MASTERCLASS.md](LLM_TESTING_MASTERCLASS.md)**. Read it sequentially; each part builds on the previous one.

| Part | Topic | Key skills |
|------|-------|-----------|
| **Part 0** | Local Setup (do once) | Ollama install, `llama3.1` + `nomic-embed-text` pull, OpenAI-compatible endpoint verification |
| **Part 1** | Foundations of LLM & Generative AI | Transformers, tokenization, temperature, context windows, RAG architecture, ChromaDB |
| **Part 2** | The Testing Framework Ecosystem | DeepEval (answer relevance, faithfulness, hallucination), Ragas (RAG-specific metrics), Promptfoo (YAML-driven multi-model eval) |
| **Part 3** | Agentic Engineering & Automation | Self-healing locators (ADR-019), testing ReAct agents, multi-agent prompt injection scenarios |
| **Part 4** | Observability & Distributed Tracing | OpenTelemetry GenAI spans, trace-id propagation into eval reports, local Jaeger (ADR-016) |

---

## ⏱️ Estimated time investment

| Goal | Estimated effort |
|------|-----------------|
| Read through the full guide once | 3–4 hours |
| Complete all Python examples hands-on | 10–14 hours |
| Work through every senior architectural challenge | +4–6 hours |
| **Total Zero-to-Hero run** | **~18–24 hours** |

Spread over 2–4 weeks at a sustainable pace, or compress into an intensive sprint. Part 0 (local setup) takes 20–30 minutes and only needs to be done once.

---

## 🛠️ Prerequisites & setup

**Python environment**
- Python 3.10+
- `pip install deepeval ragas promptfoo chromadb opentelemetry-sdk opentelemetry-exporter-otlp`

**Local LLM (required — replaces any cloud API)**
- [Ollama](https://ollama.com/) — `brew install ollama` on macOS
- Pull models once: `ollama pull llama3.1 && ollama pull nomic-embed-text`
- Ollama serves an OpenAI-compatible endpoint at `http://localhost:11434` — all frameworks use it transparently

**Optional (observability)**
- Docker Desktop — for the local Jaeger + OTLP collector used in Part 4

No API keys, no cloud accounts, no paid services required.

---

## 📏 How to use this guide

1. **Do Part 0 first, even if you're experienced.** Confirming that Ollama is serving a response before you touch evaluation code saves hours of troubleshooting later.
2. **Read each Part, then attempt its senior challenge before reading the answer.** The challenge is the highest-value content in every section. Resist skipping it.
3. **Treat every ADR callout as mandatory reading.** ADR-016 (distributed tracing) and ADR-019 (AI in test automation) establish the non-negotiable boundaries for where AI belongs in the test stack. Their local copies live in `docs/adr/`.
4. **Run the Python snippets.** Copy them into a real interpreter, change parameters, observe how metric scores shift. Probabilistic systems are learned by doing, not reading.
5. **The senior interview challenge in Part 3** ("prompt injection in a multi-agent system") is deliberately the hardest scenario in the guide. Block dedicated time for it.

---

## 🏗️ Governance

This repository is governed by the **7 Laws of QA Automation** and the Architecture Decision Records listed in **[STANDARDS.md](STANDARDS.md)**.

Key ADRs for this guide:

| ADR | Topic |
|-----|-------|
| [ADR-016](docs/adr/ADR-016-distributed-tracing-in-test-execution.md) | Distributed tracing in test execution |
| [ADR-019](docs/adr/ADR-019-ai-in-test-automation.md) | AI in test automation — boundaries, guardrails, and promotion criteria |


