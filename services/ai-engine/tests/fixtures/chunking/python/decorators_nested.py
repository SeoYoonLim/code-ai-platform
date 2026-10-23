@cache
def outer():
    def inner():
        return 1
    return inner()
class Outer:
    class Inner:
        @staticmethod
        def run():
            return 2
