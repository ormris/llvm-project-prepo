; This test makes sure there is no redundant dependent GOs in a compilation file.
;
; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db llc -filetype=obj %S/Inputs/repo_pruning_dependent.ll -o %t
; RUN: env REPOFILE=%t.db pstore-dump  -all-compilations %t.db > %t.log
; RUN: env REPOFILE=%t.db llc -filetype=obj %s -o %t1
; RUN: env REPOFILE=%t.db pstore-dump  -all-compilations %t.db > %t1.log
; RUN: diff %t.log %t1.log

target triple = "x86_64-pc-linux-gnu-repo"

define available_externally i32 @A() !repo_ticket !0 {
entry:
  %call = call i32 @B()
  ret i32 %call
}

define internal i32 @B() {
entry:
  ret i32 1
}

!repo.tickets = !{!0, !1, !2}

!0 = !TicketNode(name: "A", digest: [16 x i8] c"\BC\B0\9B/\86\B8\09I\F7P\FB\1D\DD\F1Kf", linkage: external, pruned: true)
!1 = !TicketNode(name: "B", digest: [16 x i8] c"q)Tf\00H\C1\8C\B7e\E8U\CF\19'y", linkage: internal, pruned: false)
!2 = !TicketNode(name: "B", digest: [16 x i8] c"4#\0F\1D\D2KlU*\9FM\B1\11}\90\1A", linkage: internal, pruned: true)
