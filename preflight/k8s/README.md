1. Create ns `test`: `kubectl create ns test`
2. Run single node test: `kubectl apply -f debug_job.yaml` and check pod logs.
3. Install MPI-operator: `kubectl apply -f mpi.yaml`
4. Run multi node NCCL-test: change `nodeSelector` and `tolerations` according to your cluster and run `kubectl apply -d nccl_test.yaml`, then check launcher logs.


# Note on results of NCCL tests (4th step):
You chould see logs similar to these:
```
....

new-st-gpu-2:8802:8863 [5] NCCL INFO NET/OFI Using aws-ofi-nccl 1.5.0aws
new-st-gpu-2:8802:8863 [5] NCCL INFO NET/OFI Configuring AWS-specific options

...

new-st-gpu-2:8804:8862 [6] NCCL INFO NET/OFI Selected Provider is efa (found 4 nics)
new-st-gpu-2:8804:8862 [6] NCCL INFO Using network AWS Libfabric
....

# on p4d with RDMA
...
via NET/AWS Libfabric/1/GDRDMA
...
```
