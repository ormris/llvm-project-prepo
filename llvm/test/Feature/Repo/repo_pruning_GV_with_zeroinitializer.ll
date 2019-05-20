; This testcase tests that hash generation for GV with zeroinitializer.
;
; If a global variable has zeroinitializer during the RepoMetadataGenerationPass and
; its initial value changes after the RepoMetadataGenerationPass, the digest of GV
; needs to be recalculated.

; The testcase includes three steps:
; Step 1: Build the test Inputs/repo_GV_with_zeroinitializer.ll and create the database 'clang.db' which contains the Tickets.
; Step 2: Build this file and check the function '-b' doesn't be pruned.

; This test only works for the Debug build because the digest of A is calculated for the Debug build.

; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db opt -O3 -S -mtriple=x86_64-pc-linux-gnu-repo %S/Inputs/repo_GV_with_zeroinitializer.ll  -o %t.ll
; RUN: env REPOFILE=%t.db llc -mtriple="x86_64-pc-linux-gnu-repo" -filetype=obj %t.ll -o %t.o
; RUN: env REPOFILE=%t.db opt -O3 -S -mtriple=x86_64-pc-linux-gnu-repo %s | FileCheck %s

target triple = "x86_64-pc-linux-gnu-repo"

%"StringRef" = type { i8*, i64 }
%"Entry" = type <{ %"StringRef", i64 }>

@.str.b = private unnamed_addr constant [7 x i8] c"World!\00", align 1
@_b = internal global [1 x %"Entry"] zeroinitializer, align 16
define { %"Entry"*} @_get_b() local_unnamed_addr {
  ret { %"Entry"*} { %"Entry"* getelementptr inbounds ([1 x %"Entry"], [1 x %"Entry"]* @_b, i64 0, i64 0) }
}

@llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 65535, void ()* @_GLOBAL__sub_I_b.cpp, i8* null }]

define internal void @_GLOBAL__sub_I_b.cpp() section ".text.startup" {
  store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.b, i64 0, i64 0), i8** getelementptr inbounds ([1 x %"Entry"], [1 x %"Entry"]* @_b, i64 0, i64 0, i32 0, i32 0), align 16
  ret void
}

;CHECK: !TicketNode(name: "_b", digest: [16 x i8] c"{{.+}}", linkage: internal, pruned: false)
