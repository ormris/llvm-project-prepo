; This testcase tests the program repository pruning pass.
;
; If function 'A' is dependent on function 'B' and 'B' is dependent
; on function 'C', both TickeNodes of 'B' and 'C' need to be added
; into in the 'repo.tickets' during the pruning.

; The testcase includes three steps:
; Step 1: Build the code and create the database 'clang.db' which contains all Tickets.
; Step 2: Dump all compilation members in the database;
; Step 3: Re-build the same IR code again.
; Step 4: Dump all compilation members in the database again;
; Step 5: Check that the step 2 and step 4 generate the same compilation members.

; This test only works for the Debug build because the digest of A is calculated for the Debug build.

; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db llc -mtriple="x86_64-pc-linux-gnu-repo" -filetype=obj %s -o %t
; RUN: env REPOFILE=%t.db pstore-dump  -all-compilations %t.db > %t.log
; RUN: env REPOFILE=%t.db clang -O3 -c --target=x86_64-pc-linux-gnu-repo -x ir %s  -o %t1
; RUN: env REPOFILE=%t.db pstore-dump  -all-compilations %t.db > %t1.log
; RUN: diff %t.log %t1.log

; REQUIRES: asserts

target triple = "x86_64-pc-linux-gnu-repo"

define i32 @A() !repo_ticket !0 {
entry:
  %call = call i32 @B()
  ret i32 %call
}

define internal i32 @B() {
entry:
  %call = call i32 @C()
  ret i32 %call
}

define internal i32 @C() {
entry:
  ret i32 1
}


!repo.tickets = !{!0}

!0 = !TicketNode(name: "A", digest: [16 x i8]  c"\82k\8AM\E0$d\05v\B1\AC\D8\ACdG\DB", linkage: external, pruned: false)
