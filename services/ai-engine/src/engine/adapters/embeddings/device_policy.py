"""Pure batch-boundary device selection."""

import time
from collections.abc import Callable
from enum import Enum
from typing import Literal

from engine.core.interfaces.activity import ActivityGauge

Policy = Literal["dynamic", "gpu", "cpu"]


class Device(Enum):
    GPU = 99
    CPU = 0


class DevicePolicy:
    def __init__(
        self,
        gauge: ActivityGauge | None = None,
        policy: Policy = "dynamic",
        idle_grace_s: float = 3.0,
        min_dwell_s: float = 10.0,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        if policy not in ("dynamic", "gpu", "cpu"):
            raise ValueError("invalid policy")
        if idle_grace_s < 0 or min_dwell_s < 0:
            raise ValueError("intervals must be nonnegative")
        self._gauge = gauge
        self._policy = policy
        self._grace = idle_grace_s
        self._dwell = min_dwell_s
        self._clock = clock
        self.mode = Device.CPU if policy == "cpu" else Device.GPU
        self.last_switch = -float("inf")
        self.last_busy: float | None = None

    def decide(self) -> Device:
        if self._policy != "dynamic":
            return self.mode
        now = self._clock()
        busy = self._gauge is not None and self._gauge.in_flight > 0
        if busy:
            self.last_busy = now
        if busy:
            want = Device.CPU
        elif self.last_busy is None or now - self.last_busy >= self._grace:
            want = Device.GPU
        else:
            want = self.mode
        if want != self.mode and now - self.last_switch >= self._dwell:
            self.mode = want
            self.last_switch = now
        return self.mode
