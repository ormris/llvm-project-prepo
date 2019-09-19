//===- MCSymbolRepo.h -  ---------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===---------------------------------------------------------------------===//
#ifndef LLVM_MC_MCSYMBOLREPO_H
#define LLVM_MC_MCSYMBOLREPO_H

#include "llvm/MC/MCSymbol.h"

namespace llvm {

class MCSymbolRepo : public MCSymbol {

public:
  MCSymbolRepo(const StringMapEntry<bool> *Name, bool isTemporary)
      : MCSymbol(SymbolKindRepo, Name, isTemporary) {}

  static bool classof(const MCSymbol *S) { return S->isRepo(); }

  // A pointer to the TiketNode metadata of the corresponding GlobalObject.
  const TicketNode *CorrespondingTicketNode = nullptr;

  // Get the symbol full name.
  static const std::string getFullName(const MCContext &Ctx,
                                       const StringRef InitialName,
                                       const ticketmd::DigestType &Digest) {
    std::string FullName;
    StringRef PrivateGlobalPrefix = Ctx.getAsmInfo()->getPrivateGlobalPrefix();
    FullName.reserve(PrivateGlobalPrefix.size() + InitialName.size() +
                     ticketmd::DigestSize + 1);
    FullName.append(PrivateGlobalPrefix);
    FullName.append(InitialName);
    if (Digest != ticketmd::NullDigest) {
      FullName.append(".");
      FullName.append(Digest.digest().str());
    }
    return FullName;
  }
};

} // end namespace llvm

#endif
