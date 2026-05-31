# Kombinert image: TO vLLM-servere (tekst-LLM + VLM/OCR) på ÉN GPU, bak en nginx-ruter.
# Mål: kjøre Qwen3-14B-AWQ (tekst→JSON) OG Chandra-2 (bilde→tekst) på ett Verda L40S (48 GB),
# scale-to-zero, EU. Løser "VLM+LLM samtidig" som Koyebs kvote/20 GB-tak hindret.
#
# Ruting (nginx :8000 = exposed port):
#   <base>/llm/v1/...  → vLLM Qwen3-14B-AWQ   (127.0.0.1:8001, gpu-util 0.50)
#   <base>/ocr/v1/...  → vLLM Chandra-2 (VLM)  (127.0.0.1:8002, gpu-util 0.35)
#   <base>/health      → 200 når LLM-serveren er oppe (Verda healthcheck peker hit)
#
# VRAM (L40S 48 GB): 0.50 + 0.35 = 0.85 (≈41 GB) → ~15 % headroom. Vekter ~9+10 GB, resten KV.
# Vekter er IKKE baket i v1 (lastes fra HF ved oppstart via HF_TOKEN). Baking = senere fart-opt (se README).
#
# Bygg (x86_64 — Verda GPU er amd64):  GH_USER=<bruker> ./build_and_push.sh
# Deploy: se README.md (Verda Serverless Container, port 8000, Min=0, INGEN VLLM_API_KEY).

FROM vllm/vllm-openai:v0.20.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx supervisor bash \
 && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

# Personvern/compliance: av med vLLMs anonyme telemetri (art. 9-herding).
ENV DO_NOT_TRACK=1

EXPOSE 8000
ENTRYPOINT []
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
