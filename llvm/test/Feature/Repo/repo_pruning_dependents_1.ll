; This testcase tests the program repository pruning pass.
;
; If functions 'A' and 'B' are both dependent on function 'C',
; only add a single TicketNode of 'C' to the 'repo.tickets'
; in order to avoid multiple compilation_members of function
; 'C' in the compilation.

; The testcase includes three steps:
; Step 1: Build the code and create the database 'clang.db' which contains all Tickets.
; Step 2: Dump all compilation members in the database;
; Step 3: Re-build the same IR code again.
; Step 4: Dump all compilation members in the database again;
; Step 5: Check that the step 2 and step 4 generate the same compilation members.

; This test only works for the Debug build because the digest of A is calculated for the Debug build.

; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db llc -mtriple="x86_64-pc-linux-gnu-repo" -filetype=obj %s -o %t
; RUN: env REPOFILE=%t.db pstore-dump  --all-compilations %t.db > %t.log
; RUN: env REPOFILE=%t.db clang -O3 -c --target=x86_64-pc-linux-gnu-repo -x ir %s  -o %t1
; RUN: env REPOFILE=%t.db pstore-dump  --all-compilations %t.db > %t1.log
; RUN: diff %t.log %t1.log

; REQUIRES: asserts

target triple = "x86_64-pc-linux-gnu-repo"

define i32 @A() !repo_ticket !0 {
entry:
  %call = call i32 @C()
  ret i32 %call
}

define i32 @B() !repo_ticket !1 {
entry:
  %call = call i32 @C()
  %add = add nsw i32 %call, 1
  ret i32 %add
}

define internal i32 @C() {
entry:
  ret i32 1
}


!repo.tickets = !{!0, !1}

!0 = !TicketNode(name: "A", digest: [16 x i8] c"]\e5\0d?\af\1f\15\d1~\c8\ccI\0f\14d\c0", linkage: external, visibility: default, pruned: false)
!1 = !TicketNode(name: "B", digest: [16 x i8] c"\17#\80\f3\bb\e1e94\8b\bb}\db\1df\eb", linkage: external, visibility: default, pruned: false)
