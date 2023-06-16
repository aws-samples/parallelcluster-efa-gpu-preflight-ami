1. Build Dockerfile (`jax.Dockerfile`)
2. Review `mpi.yaml` (change image to your image, along with configs like nodeSelector and tolerations)
3. Run mpi.yaml (`kubectl apply -f mpu.yaml`) - it runs synthetic test by default, uncomment 