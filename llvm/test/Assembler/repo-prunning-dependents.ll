; This testcase tests the program repository pruning pass. If the global
; variables or functions have been defined in the database 'clang.db' and
; have dependent global objects. When they are pruned, its dependnt fragments
; will be added into the repo.tickets metadata.

; The testcase includes three steps:
; Step 1: Generate the repo IR code which contains the TicketNode metadata;
; Step 2: Create the database 'clang.db' which contains all Tickets.
; Step 3: Run the ProgramRepositoryPrunningPass to optimise the repo IR code
;         which is generated by Step 1;

; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db opt -mtriple="x86_64-pc-linux-gnu-repo" -O3 -S %s -o %t
; RUN: env REPOFILE=%t.db llc -mtriple="x86_64-pc-linux-gnu-repo" -filetype=obj %t
; RUN: env REPOFILE=%t.db opt -mtriple="x86_64-pc-linux-gnu-repo" -O3 -S %s | FileCheck %s

target triple = "x86_64-pc-linux-gnu-elf"

@.input_str = private unnamed_addr constant [7 x i8] c"hello\0A\00", align 1

declare i32 @printf(i8* nocapture readonly, ...)

define void @test() align 2 {
entry:
  %call = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.input_str, i32 0, i32 0))
  ret void
}

;CHECK:      !TicketNode(name: "test",
;CHECK-NEXT: !TicketNode(name: ".input_str",
;CHECK-NEXT: !TicketNode(name: "str.
