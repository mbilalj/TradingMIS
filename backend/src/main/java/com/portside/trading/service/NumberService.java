package com.portside.trading.service;

import com.portside.trading.domain.DocSequence;
import com.portside.trading.repo.Repos.SequenceRepo;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Gap-free-per-type document numbers (INV-000001 ...) backed by a locked counter row. */
@Service
public class NumberService {

    private final SequenceRepo sequenceRepo;

    public NumberService(SequenceRepo sequenceRepo) {
        this.sequenceRepo = sequenceRepo;
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public String next(String name, String prefix) {
        DocSequence seq = sequenceRepo.lockByName(name).orElseGet(() -> sequenceRepo.saveAndFlush(new DocSequence(name)));
        long n = seq.getNextVal();
        seq.setNextVal(n + 1);
        sequenceRepo.save(seq);
        return String.format("%s-%06d", prefix, n);
    }
}
