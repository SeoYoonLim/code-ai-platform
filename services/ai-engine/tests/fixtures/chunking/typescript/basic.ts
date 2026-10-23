import { x } from "x";
interface Shape { size: number }
type ID = string;
enum Mode { A, B }
class Box {
  size = 1;
  area() { return this.size ** 2; }
}
function square(x: number) { return x*x; }
