; This test makes sure there is no redundant dependent str with the private linkage type in a compilation file.
;
; The test compiled two IR files: repo_pruning_dependent_with_private_linkage.ll and repo_prunning_dependents_3.ll and then dump all the compilations from the database.
; There are two compilations in the database, and each compilation should only contains a `str` compilation member. Therefore, the "name:str" should appear just twice.
;
;
; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db llc -filetype=obj %S/Inputs/repo_pruning_dependent_with_private_linkage.ll -o %t
; RUN: env REPOFILE=%t.db llc -filetype=obj %s -o %t1
; RUN: env REPOFILE=%t.db pstore-dump --all-compilations %t.db | FileCheck %s

target triple = "x86_64-pc-linux-gnu-repo"

@str = private unnamed_addr constant [6 x i8] c"Ipsum\00", align 1

define i32 @main() local_unnamed_addr !repo_ticket !0 {
entry:
  %puts.i = tail call i32 @puts(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @str, i64 0, i64 0))
  ret i32 0
}

declare i32 @puts(i8* nocapture readonly) local_unnamed_addr

!repo.tickets = !{!0, !1, !2}

!0 = !TicketNode(name: "main", digest: [16 x i8] c"G\A3\F3c\9D\10\142\9D\9F\89l\BCG\1DV", linkage: external, visibility: default, pruned: false)
!1 = !TicketNode(name: "a", digest: [16 x i8] c"r\D5\E2\FD\BC\F9\97\AB\1E\03\CFr\C8\AB\A3\14", linkage: external, visibility: default, pruned: true)
!2 = !TicketNode(name: "str.a7f37715537f507c6209fefc73679f01", digest: [16 x i8] c"\A7\F3w\15S\7FP|b\09\FE\FCsg\9F\01", linkage: private, visibility: default, pruned: true)

; CHECK:     name    : str
; CHECK:     name    : str
; CHECK-NOT: name    : str
