target triple = "x86_64-pc-linux-gnu-repo"

define i32 @Fn() {
entry:
  ret i32 1
}

define available_externally i32 @foo() {
  ret i32 1
}

define void @call_foo() {
  %call = call i32 @foo()
  ret void
}

@bar = alias i32(), i32()* @Fn
define i32 @test() {
entry:
  %0 = call i32() @bar()
  ret i32 %0
}
