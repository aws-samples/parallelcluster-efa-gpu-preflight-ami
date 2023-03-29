1. Create ns `test`: `kubectl create ns test`
2. Run single node test: `kubectl apply -f debug_job.yaml` and check pod logs.
3. Install MPI-operator: `kubectl apply -f mpi.yaml`
4. Run multi node NCCL-test: change `nodeSelector` and `tolerations` according to your cluster and run `kubectl apply -d nccl_test.yaml`, then check launcher logs.
