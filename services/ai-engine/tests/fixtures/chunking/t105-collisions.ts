class Box {
  get value() { return 1; }
  set value(v: number) {}
  run(v: string): string;
  run(v: number): number;
  run(v: unknown) { return v; }
}
