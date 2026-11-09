package com.portside.trading.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_attachment", indexes = @Index(columnList = "ownerType,ownerId"))
@Getter @Setter @NoArgsConstructor
public class Attachment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 24)
    private String ownerType;
    @Column(nullable = false)
    private Long ownerId;
    @Column(nullable = false, length = 255)
    private String fileName;
    @Column(nullable = false, length = 255)
    private String storedName;
    @Column(length = 128)
    private String contentType;
    private long size;
    private String uploadedBy;
    private LocalDateTime uploadedAt;
}
