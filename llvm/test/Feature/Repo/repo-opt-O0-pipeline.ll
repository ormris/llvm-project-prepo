; RUN: opt -mtriple="x86_64-pc-linux-gnu-repo" -O0 -debug-pass=Structure < %s -o /dev/null 2>&1 | FileCheck %s

; REQUIRES: asserts

; CHECK:      Profile summary info
; CHECK-NEXT:   ModulePass Manager
; CHECK-NEXT:     RepoMetadataGenerationPass
; CHECK-NEXT:     RepoPruningPass
; CHECK-NEXT:     Force set function attributes

define void @f() {
  ret void
}
