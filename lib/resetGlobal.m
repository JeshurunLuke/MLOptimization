function resetGlobal()
    ExpSeq.reset();
    SeqConfig.reset();
    NiDACBackend.clearSession();
    IRCache.get().clear();
    FPGAPoster.dropAll();
    URLPoster.dropAll();
    USRPPoster.dropAll();
    Valon.dropAll();
    EnableScan.set(1);
end
