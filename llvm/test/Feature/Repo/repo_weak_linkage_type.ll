; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db llc -filetype=obj -mtriple=x86_64-pc-linux-gnu-repo %s

target triple = "x86_64-pc-linux-gnu-repo"

@WeakData = weak global i32 0, align 4, !repo_ticket !0

!repo.tickets = !{!0}

!0 = !TicketNode(name: "WeakData", digest: [16 x i8] c"W6c\E4\A2\C0\0BH\D2_\C7\E5\91\E9\13\C9", linkage: weak, pruned: false)

