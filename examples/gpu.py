import ray

ray.init()

@ray.remote(num_gpus=1)
class GPUActor:
    def say_hello(self):
        print("I live in a pod with GPU access.")

# Request actor placement.
gpu_actors = [GPUActor.remote() for _ in range(2)]
# The following command will block until two Ray pods with GPU access are scaled
# up and the actors are placed.
ray.get([actor.say_hello.remote() for actor in gpu_actors])
