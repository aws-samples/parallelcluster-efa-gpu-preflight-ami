import jax
import sys, os, socket

# without MPI -> jax.distributed.initialize(coordinator_address="192.168.114.194:29400", num_processes=2, process_id=int(sys.argv[1])) "python main.py 0" and "python main.py 1" on separate machines
print("check", os.environ["LEAD_NODE"], int(os.environ["OMPI_COMM_WORLD_SIZE"]), int(os.environ["PMIX_RANK"]))
print("resolved IP:", socket.gethostbyname(os.environ["LEAD_NODE"]))
jax.distributed.initialize(coordinator_address=socket.gethostbyname(os.environ["LEAD_NODE"]), num_processes=int(os.environ["OMPI_COMM_WORLD_SIZE"]), process_id=int(os.environ["PMIX_RANK"]))  # On GPU, see above for the necessary arguments.print("device_count:", jax.device_count())  # total number of accelerator devices in the cluster

print("local_device_count:", jax.local_device_count())  # number of accelerator devices attached to this host
# The psum is performed over all mapped devices across the pod slice
xs = jax.numpy.ones(jax.local_device_count())
print("out: ", jax.pmap(lambda x: jax.lax.psum(x, 'i'), axis_name='i')(xs))