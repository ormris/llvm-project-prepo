; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db opt -S %s | FileCheck %s

target triple = "x86_64-pc-linux-gnu-repo"

@fp_foo = global [1 x i32 (...)*] [i32 (...)* bitcast (i32 ()* @foo to i32 (...)*)], align 8
@fp_bar = global [1 x i32 (...)*] [i32 (...)* bitcast (i32 ()* @bar to i32 (...)*)], align 8
@a = internal global i32 1, align 4
@vp_a = global [1 x i32*] [i32* @a], align 8
@b = internal global i32 1, align 4
@vp_b = global [1 x i32*] [i32* @b], align 8


define internal i32 @foo() {
entry:
  ret i32 1
}

define internal i32 @bar() {
entry:
  ret i32 1
}

;CHECK: !0 = !TicketNode(name: "fp_foo", digest: [16 x i8] c"\05\FC`\F48\E2\EEU\A7\C6m\0F\5C/yj", linkage: external, visibility: default, pruned: false)
;CHECK: !1 = !TicketNode(name: "fp_bar", digest: [16 x i8] c"\DAhfm\DEx\DA\06\7FF\86S\E4\AE\E9\FF", linkage: external, visibility: default, pruned: false)
;CHECK: !2 = !TicketNode(name: "a", digest: [16 x i8] c"\AC$P\92\CBZ\FF\00\A7\ADW\C01\BE\DB>", linkage: internal, visibility: default, pruned: false)
;CHECK: !3 = !TicketNode(name: "vp_a", digest: [16 x i8] c">\D0mA\BC\0B\02cW\B4\81wD\C1=C", linkage: external, visibility: default, pruned: false)
;CHECK: !4 = !TicketNode(name: "b", digest: [16 x i8] c"\AC$P\92\CBZ\FF\00\A7\ADW\C01\BE\DB>", linkage: internal, visibility: default, pruned: false)
;CHECK: !5 = !TicketNode(name: "vp_b", digest: [16 x i8] c"W\AE\A2\DBtS\1B\08\C4\82\9B\F4\80\9E~\C9", linkage: external, visibility: default, pruned: false)
;CHECK: !6 = !TicketNode(name: "foo", digest: [16 x i8] c"\10*j\F7-\D1\DB\C0uM}R\C0\E4\8A\8D", linkage: internal, visibility: default, pruned: false)
;CHECK: !7 = !TicketNode(name: "bar", digest: [16 x i8] c"\10*j\F7-\D1\DB\C0uM}R\C0\E4\8A\8D", linkage: internal, visibility: default, pruned: false)
