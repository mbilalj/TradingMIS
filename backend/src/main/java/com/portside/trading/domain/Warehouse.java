package com.portside.trading.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_warehouse")
@Getter @Setter @NoArgsConstructor
public class Warehouse {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String code;
    @Column(nullable = false, length = 128)
    private String name;
    @Column(length = 255)
    private String address;
    @Column(nullable = false)
    private boolean active = true;
}
