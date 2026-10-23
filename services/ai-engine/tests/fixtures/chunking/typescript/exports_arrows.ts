export const add = (x: number) => x + 1;
export const named = function(x: number) { return x; };
export default function() { return 1; }
export abstract class Base {
  abstract run(): number;
  field = () => 2;
  *items() { yield 1; }
}
export function* values() { yield 2; }
