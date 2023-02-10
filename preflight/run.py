import sys, os
import torch
import torch.distributed as dist
import torch.nn as nn
import torch.optim as optim
from torch.nn.parallel import DistributedDataParallel as DDP

class ToyModel(nn.Module):
    def __init__(self):
        super(ToyModel, self).__init__()
        self.net1 = nn.Linear(10, 10)
        self.relu = nn.ReLU()
        self.net2 = nn.Linear(10, 5)
    def forward(self, x):
        return self.net2(self.relu(self.net1(x)))

def demo_basic():
    if sys.argv[1] == "ddp":
        dist.init_process_group("nccl")
        rank = dist.get_rank()
        print(f"Start running basic DDP example on rank {rank}.")
        device_id = f"cuda:{rank % torch.cuda.device_count()}"
        print("Distributed training variables:")
        for env_key in ("LOCAL_RANK", "RANK", "GROUP_RANK", "LOCAL_WORLD_SIZE", "WORLD_SIZE"):
            print(f"{env_key}: {os.environ.get(env_key, '')}")
        print("#############")
        model = ToyModel().to(device_id)
        ddp_model = DDP(model, device_ids=[device_id])
    elif sys.argv[1] == "local":
        device_id = "cuda:0"
        model = ToyModel().to(device_id)
        pass
    else:
        raise RuntimeError(f"Unknown mode: {sys.argv[1]}")
    loss_fn = nn.MSELoss()
    optimizer = optim.SGD(model.parameters(), lr=0.001)
    for i in range(1000):
        if i % 100 == 0:
            msg = f"step: {i}"
            if sys.argv[1] == "ddp":
                msg = f"rank: {rank}, {msg}"
            print(msg)
        optimizer.zero_grad()
        outputs = model(torch.randn(20, 10).to(device_id))
        labels = torch.randn(20, 5).to(device_id)
        loss_fn(outputs, labels).backward()
        optimizer.step()

if __name__ == "__main__":
    demo_basic()
