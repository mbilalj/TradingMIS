package com.portside.trading.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_head")
@Getter @Setter @NoArgsConstructor
public class AccountHead {
    @Id @Column(length = 16)
    private String code;
    @Column(nullable = false, length = 128)
    private String name;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16)
    private HeadType type;

    public AccountHead(String code, String name, HeadType type) {
        this.code = code;
        this.name = name;
        this.type = type;
    }
}
