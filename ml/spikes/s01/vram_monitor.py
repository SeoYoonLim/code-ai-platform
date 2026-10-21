"""Whole-device memory sampling; all sizes are MiB or decimal GB explicitly."""

import json
import subprocess
import threading
import time
from pathlib import Path


def gpu_mib() -> float:
    """Read total device usage, including Windows and other processes."""
    result = subprocess.run(
        ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
        check=True,
        capture_output=True,
        text=True,
    )
    return float(result.stdout.strip().splitlines()[0])


def write_json(path: str | Path, value: object) -> None:
    """Persist measurement evidence in UTF-8."""
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(value, ensure_ascii=False) + "\n", encoding="utf-8")


class Monitor:
    """Sample device VRAM and system RAM every 0.5 seconds."""

    def __init__(self) -> None:
        self.samples: list[dict[str, float]] = []
        self.errors: list[str] = []
        self.baseline_mib = gpu_mib()
        self.stop_event = threading.Event()
        self.thread = threading.Thread(target=self._sample, daemon=True)

    def _sample(self) -> None:
        while not self.stop_event.is_set():
            try:
                sample = {"time": time.time(), "vram_mib": gpu_mib()}
                if Path("/proc/meminfo").exists():
                    info = dict(line.split(":", 1) for line in Path("/proc/meminfo").read_text().splitlines())
                    sample["system_ram_used_mib"] = (
                        int(info["MemTotal"].split()[0]) - int(info["MemAvailable"].split()[0])
                    ) / 1024
                self.samples.append(sample)
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                self.errors.append(str(error))
            self.stop_event.wait(0.5)

    def __enter__(self) -> "Monitor":
        self.thread.start()
        return self

    def __exit__(self, *args: object) -> None:
        self.stop_event.set()
        self.thread.join()

    def summary(self) -> dict[str, object]:
        """Include raw samples so peaks and means can be independently checked."""
        values = [row["vram_mib"] for row in self.samples] or [self.baseline_mib]
        return {
            "baseline_mib": self.baseline_mib,
            "peak_mib": max(values),
            "mean_mib": sum(values) / len(values),
            "peak_minus_baseline_mib": max(values) - self.baseline_mib,
            "system_ram_peak_mib": max(
                (row.get("system_ram_used_mib", 0) for row in self.samples),
                default=0,
            ),
            "samples": self.samples,
            "sampling_errors": self.errors,
        }
