~/llama.cpp/build/bin/llama-server \
  --model ~/Qwen3.5-122B-A10B/Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003.gguf \
  --ctx-size 262144 \
  --batch-size 2048 \
  --temp 0.7 --top-p 0.8 --top-k 20 \
  --threads 32 --n-gpu-layers 999 \
  --chat-template-kwargs '{"enable_thinking": false}' \
  --port 8080