package com.portside.trading.web;

import com.portside.trading.domain.Attachment;
import com.portside.trading.repo.Repos.AttachmentRepo;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.service.AccessService;
import com.portside.trading.service.DashboardService;
import com.portside.trading.service.ReportService;
import com.portside.trading.service.SearchService;
import com.portside.trading.service.SettingsService;
import com.portside.trading.web.dto.ReportResult;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

/** Dashboard, reports, global search, business settings and file attachments. */
@RestController
@RequestMapping("/api")
public class InsightController {

    private static final Set<String> ATTACHMENT_OWNERS = Set.of("SHIPMENT", "EXPENSE", "SALE");

    private final DashboardService dashboard;
    private final ReportService reports;
    private final SearchService search;
    private final SettingsService settings;
    private final AccessService access;
    private final AttachmentRepo attachmentRepo;
    private final CurrentUserService currentUser;
    private final Path uploadRoot;

    public InsightController(DashboardService dashboard, ReportService reports, SearchService search, SettingsService settings,
                             AccessService access, AttachmentRepo attachmentRepo, CurrentUserService currentUser,
                             @Value("${portside.attachments-dir:attachments}") String dir) throws IOException {
        this.dashboard = dashboard;
        this.reports = reports;
        this.search = search;
        this.settings = settings;
        this.access = access;
        this.attachmentRepo = attachmentRepo;
        this.currentUser = currentUser;
        this.uploadRoot = Paths.get(dir).toAbsolutePath().normalize();
        Files.createDirectories(uploadRoot);
    }

    @GetMapping("/dashboard")
    @PreAuthorize("@accessService.canView('dash')")
    public Map<String, Object> dashboard() {
        return dashboard.summary();
    }

    @GetMapping("/reports/{code}")
    public ReportResult report(@PathVariable String code, @RequestParam(required = false) LocalDate from,
                               @RequestParam(required = false) LocalDate to, @RequestParam(required = false) Long id,
                               @RequestParam(required = false) String q, @RequestParam(required = false) String type) {
        if (!access.canRunReport(code)) throw new AccessDeniedException("Not allowed to view this report");
        return reports.run(code, new ReportService.Params(from, to, id, q, type));
    }

    @GetMapping("/search")
    public List<Map<String, Object>> search(@RequestParam String q) {
        return search.search(q);
    }

    // ------------------------------------------------------------ settings

    @GetMapping("/settings")
    public Map<String, String> settings() {
        return settings.all();
    }

    @PutMapping("/settings")
    @PreAuthorize("@accessService.isOwner()")
    public Map<String, String> updateSettings(@RequestBody Map<String, String> body) {
        return settings.update(body);
    }

    // ------------------------------------------------------------ attachments

    @GetMapping("/attachments")
    public List<Attachment> attachments(@RequestParam String ownerType, @RequestParam Long ownerId) {
        return attachmentRepo.findByOwnerTypeAndOwnerIdOrderByIdAsc(ownerType.toUpperCase(), ownerId);
    }

    @PostMapping("/attachments")
    public Attachment upload(@RequestParam String ownerType, @RequestParam Long ownerId, @RequestParam("file") MultipartFile file) throws IOException {
        String owner = ownerType.toUpperCase();
        if (!ATTACHMENT_OWNERS.contains(owner)) throw new IllegalArgumentException("Attachments are not supported for " + ownerType);
        if (file.isEmpty()) throw new IllegalArgumentException("Choose a file to upload");
        String original = file.getOriginalFilename() == null ? "file" : Paths.get(file.getOriginalFilename()).getFileName().toString();
        String stored = UUID.randomUUID() + "-" + original.replaceAll("[^A-Za-z0-9._-]", "_");
        Files.copy(file.getInputStream(), uploadRoot.resolve(stored));
        Attachment a = new Attachment();
        a.setOwnerType(owner);
        a.setOwnerId(ownerId);
        a.setFileName(original);
        a.setStoredName(stored);
        a.setContentType(file.getContentType());
        a.setSize(file.getSize());
        a.setUploadedBy(currentUser.username());
        a.setUploadedAt(LocalDateTime.now());
        return attachmentRepo.save(a);
    }

    @GetMapping("/attachments/{id}/download")
    public ResponseEntity<Resource> download(@PathVariable Long id) {
        Attachment a = attachmentRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        Path file = uploadRoot.resolve(a.getStoredName()).normalize();
        if (!file.startsWith(uploadRoot) || !Files.exists(file)) throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        MediaType type = a.getContentType() == null ? MediaType.APPLICATION_OCTET_STREAM : MediaType.parseMediaType(a.getContentType());
        return ResponseEntity.ok()
                .contentType(type)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + a.getFileName().replace("\"", "") + "\"")
                .body(new FileSystemResource(file));
    }

    @DeleteMapping("/attachments/{id}")
    @PreAuthorize("@accessService.isOwner()")
    public void deleteAttachment(@PathVariable Long id) throws IOException {
        Attachment a = attachmentRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        Files.deleteIfExists(uploadRoot.resolve(a.getStoredName()).normalize());
        attachmentRepo.delete(a);
    }
}
