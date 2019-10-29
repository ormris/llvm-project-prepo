//===----  RepoPruning.cpp - Program repository pruning  ----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "pstore/core/database.hpp"
#include "pstore/core/hamt_map.hpp"
#include "pstore/core/index_types.hpp"
#include "pstore/mcrepo/fragment.hpp"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Triple.h"
#include "llvm/IR/CallSite.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/RepoGlobals.h"
#include "llvm/IR/RepoHashCalculator.h"
#include "llvm/IR/RepoTicket.h"
#include "llvm/Pass.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/Utils/GlobalStatus.h"
#include <algorithm>
#include <iostream>
#include <map>
using namespace llvm;

#define DEBUG_TYPE "prepo-pruning"

STATISTIC(NumFunctions, "Number of functions removed");
STATISTIC(NumVariables, "Number of variables removed");

namespace {

/// RepoPruning removes the redundant global objects.
class RepoPruning : public ModulePass {
public:
  static char ID;
  RepoPruning() : ModulePass(ID) {
    initializeRepoPruningPass(*PassRegistry::getPassRegistry());
  }

  StringRef getPassName() const override { return "RepoPruningPass"; }

  bool runOnModule(Module &M) override;

private:
  bool isObjFormatRepo(Module &M) const {
    return Triple(M.getTargetTriple()).isOSBinFormatRepo();
  }
};

} // end anonymous namespace

char RepoPruning::ID = 0;
INITIALIZE_PASS(RepoPruning, "prepo-pruning",
                "Program Repository Global Object Pruning", false, false)

ModulePass *llvm::createRepoPruningPass() { return new RepoPruning(); }

GlobalValue::LinkageTypes toGVLinkage(pstore::repo::linkage L) {
  switch (L) {
  case pstore::repo::linkage::external:
    return GlobalValue::ExternalLinkage;
  case pstore::repo::linkage::link_once_any:
    return GlobalValue::LinkOnceAnyLinkage;
  case pstore::repo::linkage::link_once_odr:
    return GlobalValue::LinkOnceODRLinkage;
  case pstore::repo::linkage::weak_any:
    return GlobalValue::WeakAnyLinkage;
  case pstore::repo::linkage::weak_odr:
    return GlobalValue::WeakODRLinkage;
  case pstore::repo::linkage::internal_no_symbol:
    return GlobalValue::PrivateLinkage;
  case pstore::repo::linkage::internal:
    return GlobalValue::InternalLinkage;
  case pstore::repo::linkage::common:
    return GlobalValue::CommonLinkage;
  case pstore::repo::linkage::append:
    return GlobalValue::AppendingLinkage;
  }
  llvm_unreachable("Unsupported linkage type");
}

GlobalValue::VisibilityTypes toGVVisibility(pstore::repo::visibility_type V) {
  switch (V) {
  case pstore::repo::visibility_type::default_visibility:
    return GlobalValue::VisibilityTypes::DefaultVisibility;
  case pstore::repo::visibility_type::hidden_visibility:
    return GlobalValue::VisibilityTypes::HiddenVisibility;
  case pstore::repo::visibility_type::protected_visibility:
    return GlobalValue::VisibilityTypes::ProtectedVisibility;
  }
  llvm_unreachable("Unsupported visibility type");
}

StringRef toStringRef(pstore::raw_sstring_view S) {
  return {S.data(), S.size()};
}

static bool isIntrinsicGV(const GlobalObject &GO) {
  return GO.getName().startswith("llvm.");
}

static bool isSafeToPruneIntrinsicGV(const GlobalObject &GO) {
  const llvm::StringRef Name = GO.getName();
  bool Result = Name == "llvm.global_ctors" || Name == "llvm.global_dtors";
  assert(!Result || isIntrinsicGV(GO));
  return Result;
}

static bool isSafeToPrune(const GlobalObject &GO) {
  return !isIntrinsicGV(GO) || isSafeToPruneIntrinsicGV(GO);
}

ticketmd::DigestType toDigestType(pstore::index::digest D) {
  ticketmd::DigestType Digest;
  support::endian::write64le(&Digest, D.low());
  support::endian::write64le(&(Digest.Bytes[8]), D.high());
  return Digest;
}

static void addDependentFragments(
    Module &M, StringSet<> &DependentFragments,
    std::shared_ptr<const pstore::index::fragment_index> const &Fragments,
    const pstore::database &Repository, pstore::index::digest const &Digest) {

  auto It = Fragments->find(Repository, Digest);
  assert(It != Fragments->end(Repository));
  // Create  the dependent fragments if existing in the repository.
  auto Fragment = pstore::repo::fragment::load(Repository, It->second);
  if (auto Dependents =
          Fragment->atp<pstore::repo::section_kind::dependent>()) {
    for (pstore::typed_address<pstore::repo::compilation_member> Dependent :
         *Dependents) {
      auto CM = pstore::repo::compilation_member::load(Repository, Dependent);
      StringRef MDName =
          toStringRef(pstore::get_sstring_view(Repository, CM->name).second);
      LLVM_DEBUG(dbgs() << "    Prunning dependent name: " << MDName << '\n');
      auto DMD = TicketNode::get(
          M.getContext(), MDName, toDigestType(CM->digest),
          toGVLinkage(CM->linkage), toGVVisibility(CM->visibility), true);
      // If functions 'A' and 'B' are dependent on function 'C', only add a
      // single TicketNode of 'C' to the 'repo.tickets' in order to avoid
      // multiple compilation_members of function 'C' in the compilation.
      if (DependentFragments.insert(MDName).second) {
        NamedMDNode *const NMD = M.getOrInsertNamedMetadata("repo.tickets");
        assert(NMD && "NamedMDNode cannot be NULL!");
        NMD->addOperand(DMD);
        // If function 'A' is dependent on function 'B' and 'B' is dependent on
        // function 'C', both TickeNodes of 'B' and 'C' need to be added into in
        // the 'repo.tickets' during the pruning.
        addDependentFragments(M, DependentFragments, Fragments, Repository,
                              CM->digest);
      }
    }
  }
}

bool RepoPruning::runOnModule(Module &M) {
  if (skipModule(M) || !isObjFormatRepo(M))
    return false;

  MDBuilder MDB(M.getContext());

  const pstore::database &Repository = getRepoDatabase();

  std::shared_ptr<const pstore::index::fragment_index> const Fragments =
      pstore::index::get_index<pstore::trailer::indices::fragment>(Repository,
                                                                   false);

  if (!Fragments && !M.getNamedMetadata("repo.tickets")) {
    return false;
  }

  std::map<pstore::index::digest, const GlobalObject *> ModuleFragments;
  StringSet<> DependentFragments; // Record all dependents.

  // Erase the unchanged global objects.
  auto EraseUnchangedGlobalObject =
      [&ModuleFragments, &Fragments, &Repository, &M,
       &DependentFragments](GlobalObject &GO, llvm::Statistic &NumGO) -> bool {
    if (GO.isDeclaration() || GO.hasAvailableExternallyLinkage() ||
        !isSafeToPrune(GO))
      return false;
    auto const Result = ticketmd::get(&GO);
    assert(!Result.second && "The repo_ticket metadata should be created by "
                             "the RepoMetadataGeneration pass!");

    auto const Key =
        pstore::index::digest{Result.first.high(), Result.first.low()};

    bool InRepository = true;
    if (!Fragments) {
      InRepository = false;
    } else {
      auto It = Fragments->find(Repository, Key);
      if (It == Fragments->end(Repository)) {
        LLVM_DEBUG(dbgs() << "New GO name: " << GO.getName() << '\n');
        InRepository = false;
      } else {
        LLVM_DEBUG(dbgs() << "Prunning GO name: " << GO.getName() << '\n');
        addDependentFragments(M, DependentFragments, Fragments, Repository,
                              Key);
      }
    }

    if (!InRepository) {
      auto It = ModuleFragments.find(Key);
      // The definition of some global objects may be discarded if not used.
      // If a global has been pruned and its digest matches a discardable GO,
      // a missing fragment error might be met during the assembler. To avoid
      // this issue, this global object can't be pruned if the referenced
      // global object is discardable.
      if (It == ModuleFragments.end() || It->second->isDiscardableIfUnused()) {
        LLVM_DEBUG(dbgs() << "Putting GO name into ModuleFragments: "
                          << GO.getName() << '\n');
        ModuleFragments.emplace(Key, &GO);
        return false;
      }
    }

    ++NumGO;
    GO.setComdat(nullptr);
    GO.setDSOLocal(false);
    TicketNode *MD =
        dyn_cast<TicketNode>(GO.getMetadata(LLVMContext::MD_repo_ticket));
    MD->setPruned(true);

    if (isSafeToPruneIntrinsicGV(GO)) {
      // Change Intrinsic GV from definition to declaration.
      GO.clearMetadata();
      GO.setMetadata(LLVMContext::MD_repo_ticket, MD);
      GO.setLinkage(GlobalValue::ExternalLinkage);
      GlobalVariable *const GV = dyn_cast<GlobalVariable>(&GO);
      Constant *const Init = GV->getInitializer();
      if (isSafeToDestroyConstant(Init))
        Init->destroyConstant();
      GV->setInitializer(nullptr);
      return true;
    }

    GO.setLinkage(GlobalValue::AvailableExternallyLinkage);
    return true;
  };

  bool Changed = false;
  for (GlobalVariable &GV : M.globals()) {
    if (EraseUnchangedGlobalObject(GV, NumVariables)) {
      Changed = true;
    }
  }

  for (Function &Func : M) {
    if (EraseUnchangedGlobalObject(Func, NumFunctions)) {
      Changed = true;
    }
  }

  LLVM_DEBUG(dbgs() << "size of module: " << M.size() << '\n');
  LLVM_DEBUG(dbgs() << "size of removed functions: " << NumFunctions << '\n');
  LLVM_DEBUG(dbgs() << "size of removed variables: " << NumVariables << '\n');

  return Changed;
}
