"""Device transitions use observed busy time and fake clocks."""

from itertools import pairwise

import pytest

from engine.adapters.embeddings.device_policy import Device, DevicePolicy


class Gauge:
    def __init__(self) -> None:
        self.value = 0
        self.reads = 0

    @property
    def in_flight(self) -> int:
        self.reads += 1
        return self.value


class Clock:
    value = 0.0

    def __call__(self) -> float:
        return self.value


def test_observed_busy_grace_and_dwell() -> None:
    gauge, clock = Gauge(), Clock()
    policy = DevicePolicy(gauge, idle_grace_s=3, min_dwell_s=10, clock=clock)
    assert policy.mode == Device.GPU
    assert gauge.reads == 0
    assert policy.decide() == Device.GPU
    gauge.value = 1
    assert policy.decide() == Device.CPU
    clock.value = 2
    assert policy.decide() == Device.CPU
    assert policy.last_busy == 2
    gauge.value = 0
    clock.value = 4.9
    assert policy.decide() == Device.CPU
    clock.value = 5
    assert policy.decide() == Device.CPU
    clock.value = 10
    assert policy.decide() == Device.GPU
    gauge.value = 1
    clock.value = 11
    assert policy.decide() == Device.GPU
    clock.value = 20
    assert policy.decide() == Device.CPU


def test_grace_is_from_last_busy_not_first_idle() -> None:
    gauge, clock = Gauge(), Clock()
    gauge.value = 1
    policy = DevicePolicy(gauge, min_dwell_s=0, clock=clock)
    assert policy.decide() == Device.CPU
    gauge.value = 0
    clock.value = 3
    assert policy.decide() == Device.GPU


@pytest.mark.parametrize(("policy", "device"), [("gpu", Device.GPU), ("cpu", Device.CPU)])
def test_fixed(policy: str, device: Device) -> None:
    from engine.adapters.embeddings.device_policy import Policy

    # Parametrized strings are narrowed before passing the Literal contract.
    selected: Policy = "cpu" if policy == "cpu" else "gpu"
    gauge = Gauge()
    gauge.value = 1
    instance = DevicePolicy(gauge, selected)
    assert instance.mode == device
    assert instance.decide() == device
    assert gauge.reads == 0


def test_absent_gauge_and_flapping() -> None:
    assert DevicePolicy().decide() == Device.GPU
    gauge, clock = Gauge(), Clock()
    policy = DevicePolicy(gauge, idle_grace_s=0, min_dwell_s=10, clock=clock)
    switches: list[float] = []
    for tick in range(100):
        clock.value = float(tick)
        gauge.value = tick % 2
        before = policy.mode
        policy.decide()
        if policy.mode != before:
            switches.append(clock.value)
    assert len(switches) > 1
    assert all(b - a >= 10 for a, b in pairwise(switches))


@pytest.mark.parametrize(("grace", "dwell"), [(-1, 0), (0, -1)])
def test_invalid_intervals(grace: float, dwell: float) -> None:
    with pytest.raises(ValueError, match="nonnegative"):
        DevicePolicy(idle_grace_s=grace, min_dwell_s=dwell)


def test_idle_grace_holds_cpu_on_its_own() -> None:
    """idle_grace_s must work independently of min_dwell_s.

    With min_dwell_s > idle_grace_s the dwell rule hides the grace rule (a return to GPU is blocked
    either way), so a policy that ignored idle_grace_s entirely still passed every other test.
    Setting min_dwell_s=0 isolates the grace rule: just after a busy observation the device must stay
    CPU, and only return to GPU once idle_grace_s has passed since the LAST observed busy.
    """
    gauge, clock = Gauge(), Clock()
    policy = DevicePolicy(gauge, idle_grace_s=3, min_dwell_s=0, clock=clock)
    gauge.value = 1
    clock.value = 10.0
    assert policy.decide() is Device.CPU
    gauge.value = 0
    clock.value = 11.0  # idle, but only 1 s since the last busy observation (< grace 3 s)
    assert policy.decide() is Device.CPU
    clock.value = 12.9  # still < 3 s
    assert policy.decide() is Device.CPU
    clock.value = 13.0  # exactly grace seconds since busy at t=10 -> GPU again
    assert policy.decide() is Device.GPU
