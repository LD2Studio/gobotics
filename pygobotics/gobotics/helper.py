import time

class Timer:
    def start(self, delay):
        self.start_time = time.time()
        self.delay = delay
    def is_elapsed(self):
        return (time.time() - self.start_time) > self.delay
    
class StateMachine:
    def __init__(self, states) -> None:
        self.states = states
        self.activate = False
    
    def start(self, init_state) -> None:
        self.running = True
        self.state = init_state
        self.once = True
        self.new_once = False

    def stop(self) -> None:
        self.running = False

    def update(self):
        self.states[self.state](self.once)
        if self.new_once:
            self.once = True
            self.new_once = False
        else:
            self.once = False

    def to(self, name) -> None:
        self.state = name
        self.new_once = True

def clamp(num, min_value, max_value):
   return max(min(num, max_value), min_value)