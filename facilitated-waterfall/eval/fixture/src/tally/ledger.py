"""The ledger: entries in date order, and the balance up to a day (task-002)."""
from dataclasses import dataclass
from datetime import date


@dataclass(frozen=True)
class Entry:
    day: date
    cents: int  # adr-0002: amounts are integer cents
    memo: str = ""


class Ledger:
    def __init__(self):
        self._entries = []

    def record(self, entry):
        """Store an entry, keeping the list in date order (task-001)."""
        self._entries.append(entry)
        self._entries.sort(key=lambda e: e.day)

    def entries(self):
        return list(self._entries)

    def balance(self, upto):
        """Sum of every entry dated on or before `upto` (plan-001: one pass)."""
        total = 0
        for e in self._entries:
            if e.day < upto:
                total += e.cents
            else:
                break
        return total
