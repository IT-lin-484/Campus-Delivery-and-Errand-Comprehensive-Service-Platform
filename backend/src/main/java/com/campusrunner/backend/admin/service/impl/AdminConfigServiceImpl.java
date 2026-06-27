package com.campusrunner.backend.admin.service.impl;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.campusrunner.backend.admin.dto.AdminConfigResponse;
import com.campusrunner.backend.admin.dto.AdminUpdateConfigRequest;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.entity.SystemConfig;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;
import com.campusrunner.backend.admin.dao.SystemConfigDao;

/**
 * 绯荤粺閰嶇疆绠＄悊鏈嶅姟銆? */
@Service
public class AdminConfigServiceImpl implements com.campusrunner.backend.admin.service.AdminConfigService {

    private static final int DEFAULT_CANCEL_WINDOW_RUNNER = 5;
    private static final int DEFAULT_CANCEL_WINDOW_REQUESTER = 5;
    private static final int DEFAULT_EXPIRE_GRACE = 30;
    private static final int DEFAULT_MAX_CONCURRENT = 2;
    private static final int DEFAULT_MAX_DAILY_ACCEPT = 10;

    private final SystemConfigDao systemConfigDao;
    private final AdminAuditLogDao adminAuditLogDao;

    public AdminConfigServiceImpl(
            SystemConfigDao systemConfigDao,
            AdminAuditLogDao adminAuditLogDao) {
        this.systemConfigDao = systemConfigDao;
        this.adminAuditLogDao = adminAuditLogDao;
    }

    @Transactional
    public AdminConfigResponse getConfig() {
        SystemConfig config = loadOrCreate();
        return toResponse(config);
    }

    @Transactional
    public AdminConfigResponse updateConfig(Long adminId, AdminUpdateConfigRequest request) {
        SystemConfig config = loadOrCreate();
        String before = toSnapshot(config);

        config.setCancelWindowRunnerMinutes(request.getCancelWindowRunnerMinutes());
        config.setCancelWindowRequesterMinutes(request.getCancelWindowRequesterMinutes());
        config.setExpireGraceMinutes(request.getExpireGraceMinutes());
        config.setMaxConcurrentOrders(request.getMaxConcurrentOrders());
        config.setMaxDailyAccept(request.getMaxDailyAccept());

        SystemConfig saved = systemConfigDao.save(config);
        writeAuditLog(adminId, before, toSnapshot(saved));
        return toResponse(saved);
    }

    private SystemConfig loadOrCreate() {
        return systemConfigDao.findTopByOrderByIdAsc()
                .orElseGet(() -> {
                    SystemConfig config = new SystemConfig();
                    config.setCancelWindowRunnerMinutes(DEFAULT_CANCEL_WINDOW_RUNNER);
                    config.setCancelWindowRequesterMinutes(DEFAULT_CANCEL_WINDOW_REQUESTER);
                    config.setExpireGraceMinutes(DEFAULT_EXPIRE_GRACE);
                    config.setMaxConcurrentOrders(DEFAULT_MAX_CONCURRENT);
                    config.setMaxDailyAccept(DEFAULT_MAX_DAILY_ACCEPT);
                    return systemConfigDao.save(config);
                });
    }

    private AdminConfigResponse toResponse(SystemConfig config) {
        AdminConfigResponse response = new AdminConfigResponse();
        response.setId(config.getId());
        response.setCancelWindowRunnerMinutes(config.getCancelWindowRunnerMinutes());
        response.setCancelWindowRequesterMinutes(config.getCancelWindowRequesterMinutes());
        response.setExpireGraceMinutes(config.getExpireGraceMinutes());
        response.setMaxConcurrentOrders(config.getMaxConcurrentOrders());
        response.setMaxDailyAccept(config.getMaxDailyAccept());
        response.setUpdatedAt(config.getUpdatedAt());
        return response;
    }

    private String toSnapshot(SystemConfig config) {
        return "{"
                + "\"cancelWindowRunnerMinutes\":" + config.getCancelWindowRunnerMinutes() + ","
                + "\"cancelWindowRequesterMinutes\":" + config.getCancelWindowRequesterMinutes() + ","
                + "\"expireGraceMinutes\":" + config.getExpireGraceMinutes() + ","
                + "\"maxConcurrentOrders\":" + config.getMaxConcurrentOrders() + ","
                + "\"maxDailyAccept\":" + config.getMaxDailyAccept()
                + "}";
    }

    private void writeAuditLog(Long operatorId, String beforeData, String afterData) {
        AdminAuditLog log = new AdminAuditLog();
        log.setOperatorId(operatorId);
        log.setAction("UPDATE_CONFIG");
        log.setTargetType("SYSTEM_CONFIG");
        log.setTargetId(1L);
        log.setBeforeData(beforeData);
        log.setAfterData(afterData);
        log.setNote("鏇存柊绯荤粺閰嶇疆");
        adminAuditLogDao.save(log);
    }
}

