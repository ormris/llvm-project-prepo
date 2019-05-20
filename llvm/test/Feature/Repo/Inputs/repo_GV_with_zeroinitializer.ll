target triple = "x86_64-pc-linux-gnu-repo"

%"StringRef" = type { i8*, i64 }
%"Entry" = type <{ %"StringRef", i64 }>

@.str.a = private unnamed_addr constant [6 x i8] c"Hello\00", align 1
@_a = internal global [1 x %"Entry"] zeroinitializer, align 16
define { %"Entry"*} @_get_a() local_unnamed_addr {
  ret { %"Entry"*} { %"Entry"* getelementptr inbounds ([1 x %"Entry"], [1 x %"Entry"]* @_a, i64 0, i64 0) }
}

@llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @_GLOBAL__sub_I_a.cpp, i8* null }]

define internal void @_GLOBAL__sub_I_a.cpp() section ".text.startup" {
  store i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.a, i64 0, i64 0), i8** getelementptr inbounds ([1 x %"Entry"], [1 x %"Entry"]* @_a, i64 0, i64 0, i32 0, i32 0), align 16
  ret void
}
