class Box:
    @property
    def value(self):
        return 1

    @value.setter
    def value(self, v):
        pass

    class Inner:
        def run(self):
            pass

    class Inner:  # noqa: F811 - deliberate same-name declarations for ID collision coverage
        def run(self):
            pass
