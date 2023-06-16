cd /workspace/transformers/examples/flax/question-answering/

/opt/conda/bin/python run_qa_custom.py \
  --model_name_or_path bert-base-uncased \
  --dataset_name squad \
  --do_train   \
  --max_seq_length 384 \
  --doc_stride 128 \
  --learning_rate 3e-5 \
  --num_train_epochs 20 \
  --per_device_train_batch_size 12 \
  --output_dir ./bert-qa-squad
