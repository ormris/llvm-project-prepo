target triple = "x86_64-pc-linux-gnu-repo"

%"class.llvm::StringRef" = type { i8*, i64 }
%"struct.llvm::EnumEntry" = type <{ %"class.llvm::StringRef", %"class.llvm::StringRef", i16, [6 x i8] }>

@_ZL15TrampolineNames = internal global [2 x %"struct.llvm::EnumEntry"] zeroinitializer, align 16