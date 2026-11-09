package com.portside.trading.service;

import com.portside.trading.domain.Role;
import com.portside.trading.security.CurrentUserService;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;

/** Module view/edit matrix, enforced server-side via @PreAuthorize and mirrored in the UI for menu hiding. */
@Service
public class AccessService {

    private final CurrentUserService currentUser;

    public AccessService(CurrentUserService currentUser) {
        this.currentUser = currentUser;
    }

    private static final Map<Role, Set<String>> VIEW = Map.of(
            Role.ACCOUNTANT, Set.of("dash", "products", "receiving", "stock", "adjustments", "sales", "returns", "customers",
                    "receipts", "suppliers", "supplierpay", "expenses", "cash", "reports", "finreports"),
            Role.SALES_OFFICER, Set.of("dash", "products", "stock", "sales", "returns", "customers", "receipts", "reports"),
            Role.STORE_KEEPER, Set.of("dash", "products", "receiving", "stock", "adjustments"),
            Role.IMPORT_DESK, Set.of("dash", "products", "receiving", "stock", "suppliers", "reports")
    );

    private static final Map<String, Set<Role>> EDIT = Map.ofEntries(
            Map.entry("products", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.STORE_KEEPER, Role.IMPORT_DESK)),
            Map.entry("receiving", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.STORE_KEEPER, Role.IMPORT_DESK)),
            Map.entry("adjustments", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.STORE_KEEPER)),
            Map.entry("sales", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.SALES_OFFICER)),
            Map.entry("returns", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.SALES_OFFICER)),
            Map.entry("customers", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.SALES_OFFICER)),
            Map.entry("receipts", Set.of(Role.OWNER, Role.ACCOUNTANT)),
            Map.entry("suppliers", Set.of(Role.OWNER, Role.ACCOUNTANT, Role.IMPORT_DESK)),
            Map.entry("supplierpay", Set.of(Role.OWNER, Role.ACCOUNTANT)),
            Map.entry("expenses", Set.of(Role.OWNER, Role.ACCOUNTANT)),
            Map.entry("cash", Set.of(Role.OWNER, Role.ACCOUNTANT))
    );

    public boolean canView(String module) {
        Role role = currentUser.role();
        if (role == null) return false;
        if (role == Role.OWNER) return true;
        Set<String> allowed = VIEW.get(role);
        return allowed != null && allowed.contains(module);
    }

    public boolean canEdit(String module) {
        Role role = currentUser.role();
        if (role == null) return false;
        if (role == Role.OWNER) return true;
        Set<Role> allowed = EDIT.get(module);
        return allowed != null && allowed.contains(role);
    }

    public boolean isOwner() {
        return currentUser.role() == Role.OWNER;
    }

    /** Anything that reveals the books, profit or cost needs the finance permission. */
    public boolean canRunReport(String code) {
        return ReportService.FINANCIAL.contains(code) ? canView("finreports") : canView("reports");
    }
}
