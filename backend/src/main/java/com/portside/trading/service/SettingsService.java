package com.portside.trading.service;

import com.portside.trading.domain.AppSetting;
import com.portside.trading.repo.AppSettingRepository;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Business details printed on invoices plus a few global defaults, stored in the shared app_setting table. */
@Service
public class SettingsService {

    public static final Map<String, String> DEFAULTS = new LinkedHashMap<>();
    static {
        DEFAULTS.put("business.name", "Portside Trading");
        DEFAULTS.put("business.address", "Lahore, Pakistan");
        DEFAULTS.put("business.phone", "");
        DEFAULTS.put("business.email", "");
        DEFAULTS.put("business.taxNo", "");
        DEFAULTS.put("invoice.footer", "Thank you for your business.");
        DEFAULTS.put("tax.defaultPct", "0");
        DEFAULTS.put("books.startDate", "");
    }

    private final AppSettingRepository repo;

    public SettingsService(AppSettingRepository repo) {
        this.repo = repo;
    }

    @Transactional(readOnly = true)
    public Map<String, String> all() {
        Map<String, String> out = new LinkedHashMap<>(DEFAULTS);
        repo.findAll().forEach(s -> {
            if (DEFAULTS.containsKey(s.getSettingKey())) out.put(s.getSettingKey(), s.getSettingValue());
        });
        return out;
    }

    public String get(String key) {
        return repo.findById(key).map(AppSetting::getSettingValue).orElse(DEFAULTS.getOrDefault(key, ""));
    }

    @Transactional
    public Map<String, String> update(Map<String, String> values) {
        values.forEach((k, v) -> {
            if (!DEFAULTS.containsKey(k)) return;
            repo.save(AppSetting.builder().settingKey(k).settingValue(v == null ? "" : v).build());
        });
        return all();
    }

    @Transactional
    public void setIfAbsent(String key, String value) {
        if (!repo.existsById(key)) repo.save(AppSetting.builder().settingKey(key).settingValue(value).build());
    }
}
