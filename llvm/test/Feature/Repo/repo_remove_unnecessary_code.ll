; This testcase tests the unnecessary codes are removed during the second time build.
;
; The testcase includes five steps:
; Step 1: Build the code and create the database 'clang.db'.
; Step 2: Dump all compilation members in the database;
; Step 3: Re-build the same IR code again.
; Step 4: Dump all compilation members in the database again;
; Step 5: Check that the step 2 and step 4 generate the same compilation members.

; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db opt -O3 -S -mtriple=x86_64-pc-linux-gnu-repo %s -o %t.ll
; RUN: env REPOFILE=%t.db llc -mtriple="x86_64-pc-linux-gnu-repo" -filetype=obj %t.ll -o %t.o
; RUN: env REPOFILE=%t.db pstore-dump  -all-compilations %t.db > %t.log
; RUN: env REPOFILE=%t.db opt -O3 -S -mtriple=x86_64-pc-linux-gnu-repo %s -o %t1.ll
; RUN: env REPOFILE=%t.db llc -mtriple="x86_64-pc-linux-gnu-repo" -filetype=obj %t1.ll -o %t1.o
; RUN: env REPOFILE=%t.db pstore-dump  -all-compilations %t.db > %t1.log
; RUN: diff %t.log %t1.log

target triple = "x86_64-pc-linux-gnu-elf"

%"String" = type { i8* }
%"Entry" = type { %"String" }
%"Array" = type { %"Entry"*, i64 }

@_Names = global [1 x %"Entry"] zeroinitializer, align 16
@.str = private unnamed_addr constant [5 x i8] c"Read\00", align 1
@llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @_GLOBAL__sub_I_EnumTables.cpp, i8* null }]

declare i64 @strlen(i8*)
define void @_A(%"String"*, i8*) align 2 {
  %3 = getelementptr inbounds %"String", %"String"* %0, i32 0, i32 0
  store i8* %1, i8** %3, align 8
  %4 = icmp ne i8* %1, null
  br i1 %4, label %5, label %7
  %6 = call i64 @strlen(i8* %1)
  br label %7
  ret void
}

define internal void @__cxx_global_var_init() {
  %1 = alloca %"String", align 8
  call void @_A(%"String"* %1, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str, i32 0, i32 0))
  %2 = bitcast %"String"* %1 to { i8*, i64 }*
  %3 = getelementptr inbounds { i8*, i64 }, { i8*, i64 }* %2, i32 0, i32 0
  %4 = load i8*, i8** %3, align 8
  %5 = getelementptr inbounds [1 x %"Entry"], [1 x %"Entry"]* @_Names, i64 0, i64 0
  %6 = getelementptr inbounds %"Entry", %"Entry"* %5, i64 0, i32 0, i32 0
  store i8* %4, i8** %6, align 8
  ret void
}

define internal void @_GLOBAL__sub_I_EnumTables.cpp() {
  call void @__cxx_global_var_init()
  ret void
}
