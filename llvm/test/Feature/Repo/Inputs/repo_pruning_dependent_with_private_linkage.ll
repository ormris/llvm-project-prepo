target triple = "x86_64-pc-linux-gnu-repo"

@str = private unnamed_addr constant [6 x i8] c"Ipsum\00", align 1

define void @g() local_unnamed_addr !repo_ticket !0 {
entry:
  %puts = tail call i32 @puts(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @str, i64 0, i64 0))
  ret void
}

declare i32 @puts(i8* nocapture readonly) local_unnamed_addr
!repo.tickets = !{!0}

!0 = !TicketNode(name: "g", digest: [16 x i8] c"r\D5\E2\FD\BC\F9\97\AB\1E\03\CFr\C8\AB\A3\14", linkage: external, visibility: default, pruned: false)
