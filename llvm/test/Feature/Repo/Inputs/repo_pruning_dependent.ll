target triple = "x86_64-pc-linux-gnu-repo"

define i32 @A() !repo_ticket !0 {
entry:
  %call = call i32 @B()
  ret i32 %call
}

define internal i32 @B() {
entry:
  ret i32 1
}


!repo.tickets = !{!0}

!0 = !TicketNode(name: "A", digest: [16 x i8] c"\BC\B0\9B/\86\B8\09I\F7P\FB\1D\DD\F1Kf", linkage: external, visibility: default, pruned: false)
