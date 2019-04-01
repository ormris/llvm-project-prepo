; Check the filename is contributed to the internal GV hash value.
;
; RUN: rm -f %t.db
; RUN: env REPOFILE=%t.db opt -S %S/Inputs/repo_internal_GV.ll -o %t 2>&1
; RUN: env REPOFILE=%t.db llc -filetype=obj %t -o /dev/null 2>&1
; RUN: env REPOFILE=%t.db opt -S %s | FileCheck %s


target triple = "x86_64-pc-linux-gnu-repo"

%"class.llvm::StringRef" = type { i8*, i64 }

%"struct.llvm::EnumEntry" = type <{ %"class.llvm::StringRef", %"class.llvm::StringRef", i16, [6 x i8] }>

@_ZL13LabelTypeEnum = internal global [2 x %"struct.llvm::EnumEntry"] zeroinitializer, align 16

;CHECK: !0 = !TicketNode(name: "_ZL13LabelTypeEnum", digest: [16 x i8] c"{{.*}}", linkage: internal, pruned: false)